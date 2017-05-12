package App::JobLog::Log::Line;
$App::JobLog::Log::Line::VERSION = '1.042';
# ABSTRACT: encapsulates one line of log text


use Modern::Perl;
use Class::Autouse qw{DateTime};
use autouse 'App::JobLog::Time' => qw(now tz);

# represents a single non-comment line in the log
# not using Moose to keep CLI snappy

# to_string method for convenience
use overload '""' => \&to_string;
use overload 'bool' => sub { 1 };

# some global variables for use in BNF regex
our ( $date, @tags, @description, $is_beginning, $is_note );

# log line parser
our $re = qr{
    ^ (?&ts) (?&non_ts) $
    (?(DEFINE)
     (?<ts> (\d{4}\s++\d++\s++\d++\s++\d++\s++\d++\s++\d++) (?{$date = $^N}) )
     (?<non_ts> (?&note) | (?&duration_mark) )
     (?<duration_mark> : (?: (?&done) | (?&event) ) )
     (?<done> DONE )
     (?<note> <NOTE> (?&event) (?{$is_note = 1}) )
     (?<event> (?&tags) : (?&descriptions) (?{$is_beginning = 1}) )
     (?<tags> (?:(?&tag)(\s++(?&tag))*+)?)
     (?<tag> ((?:[^\s:\\]|(?&escaped))++) (?{push @tags, $^N}))
     (?<escaped> \\.)
     (?<descriptions> (?: (?&description) (?: ; \s*+ (?&description) )*+ )? )
     (?<description> ((?:[^;\\]|(?&escaped))++) (?{push @description, $^N}))
    )
}xi;


sub new {
    my ( $class, @args ) = @_;
    $class = ref $class || $class;
    my %opts = @args;

    # validate %opts
    my $self = bless {}, $class;
    if ( exists $opts{comment} ) {
        $self->{comment} = $opts{comment};
        delete $opts{comment};
        die 'inconsistent arguments: ' . join( ', ', @args ) if keys %opts;
    }
    elsif ( exists $opts{done} ) {
        my $time = $opts{time};
        die "invalid value for time: $time"
          if $time && ref $time ne 'DateTime';
        $self->{time} = $time || now;
        $self->{done} = 1;
        delete $opts{done};
        delete $opts{time};
        die 'inconsistent arguments: ' . join( ', ', @args ) if keys %opts;
    }
    elsif ( exists $opts{time} ) {
        my $time = $opts{time};
        die "invalid value for time: $time"
          if $time && ref $time ne 'DateTime';
        $self->{time} = $time;
        my $tags = $opts{tags};
        die 'invalid value for tags: ' . $tags
          if defined $tags && ref $tags ne 'ARRAY';
        unless ($tags) {
            $tags = [];
            $self->{tags_unspecified} = 1;
        }
        $self->{tags} = $tags;
        my $description = $opts{description};
        if ( my $type = ref $description ) {
            die 'invalid type for description: ' . $type
              unless $type eq 'ARRAY';
            $self->{description} = $description;
        }
        elsif ( defined $description ) {

            # normalize whitespace; this is useful for testing
            $description =~ s/^\s++|\s++$//g;
            $description =~ s/\s++/ /g;
            
            $description = [$description];
        }
        else {
            $description = [];
        }
        $self->{description} = $description;
        delete @opts{qw(time tags description)};
        die 'inconsistent arguments: ' . join( ', ', @args ) if keys %opts;
    }
    elsif ( exists $opts{text} ) {
        die 'text lines in log must be blank' if $opts{text} =~ /\S/;
        $self->{text} = $opts{text} . '';
        delete $opts{text};
        die 'inconsistent arguments: ' . join( ', ', @args ) if keys %opts;
    }
    return $self;
}


sub parse {
    my ( $class, $text ) = @_;
    my $obj = bless { text => $text }, $class;
    if ( $text =~ /^\s*(?:#\s*+(.*?)\s*)?$/ ) {
        if ( defined $1 ) {
            $obj->{comment} = $1;
            delete $obj->{text};
        }
        return $obj;
    }
    local ( $date, @tags, @description, $is_beginning, $is_note );
    if ( $text =~ $re ) {

        # must use to_string to obtain text
        delete $obj->{text};
        my @time = split /\s++/, $date;
        $date = DateTime->new(
            year      => $time[0],
            month     => $time[1],
            day       => $time[2],
            hour      => $time[3],
            minute    => $time[4],
            second    => $time[5],
            time_zone => tz,
        );
        $obj->{time} = $date;
        if ($is_beginning) {
            my %tags = map { $_ => 1 } @tags;
            $obj->{tags} =
              [ map { ( my $v = $_ ) =~ s/\\(.)/$1/g; $v } sort keys %tags ];
            $obj->{description} = [
                map {
                    ( my $v = $_ ) =~ s/\\(.)/$1/g;
                    $v =~ s/^\s++|\s++$//g;
                    $v =~ s/\s++/ /g;
                    $v
                  } @description
            ];
            $obj->{note} = 1 if $is_note;
        }
        else {
            $obj->{done} = 1;
        }
        return $obj;
    }
    else {
        $obj->{malformed} = 1;
    }
    return $obj;
}


sub clone {
    my ($self) = @_;
    my $clone = bless {}, ref $self;
    if ( $self->is_malformed ) {
        $clone->{malformed} = 1;
        $clone->text = $self->text;
    }
    elsif ( $self->is_event ) {
        $clone->time = $self->time->clone;
        if ( $self->is_beginning ) {
            $clone->{note} = 1 if $self->is_note;
            $clone->tags = [ @{ $self->tags } ];
            $clone->description = [ @{ $self->description } ];
        }
    }
    else {
        $clone->comment = $self->comment if $self->is_comment;
        $clone->text    = $self->text    if exists $self->{text};
    }
    return $clone;
}


sub to_string {
    my ($self) = @_;
    return $self->{text} if exists $self->{text};
    if ( $self->is_event ) {
        my $text = $self->time_stamp;
        $text .= $self->is_note ? '<NOTE>' : ':';
        if ( $self->is_beginning ) {
            $self->tags ||= [];
            my %tags = map { $_ => 1 } @{ $self->tags };
            $text .= join ' ', map { s/([:\\\s])/\\$1/g; $_ } sort keys %tags;
            $text .= ':';
            $self->description ||= [];
            $text .= join ';',
              map { ( my $d = $_ ) =~ s/([;\\])/\\$1/g; $d }
              @{ $self->description };
        }
        else {
            $text .= 'DONE';
        }
        return $text;
    }
    elsif ( $self->is_comment ) {
        return '# ' . $self->comment;
    }
}


sub time_stamp {
    my ( $self, $time ) = @_;
    $time ||= $self->time;
    return sprintf '%d %2s %2s %2s %2s %2s', $time->year, $time->month,
      $time->day,    $time->hour,
      $time->minute, $time->second;
}

# a bunch of attributes, here for convenience


sub text : lvalue {
    $_[0]->{text};
}


sub tags : lvalue {
    $_[0]->{tags};
}


sub comment : lvalue {
    $_[0]->{comment};
}


sub time : lvalue {
    $_[0]->{time};
}


sub description : lvalue {
    $_[0]->{description};
}

# a bunch of tests


sub is_malformed { exists $_[0]->{malformed} }


sub is_beginning { exists $_[0]->{tags} }


sub is_end { $_[0]->{done} }


sub is_note { $_[0]->{note} }


sub is_event { $_[0]->{time} }


sub is_endpoint { $_[0]->{time} && !$_[0]->{note} }


sub is_comment { exists $_[0]->{comment} }


sub tags_unspecified { $_[0]->{tags_unspecified} }


sub is_blank {
    !( $_[0]->is_malformed || $_[0]->is_comment || $_[0]->is_event );
}

# some useful methods


sub comment_out {
    my ($self) = @_;
    my $text = $self->to_string;
    delete $self->{$_} for keys %$self;
    $self->{comment} = $text;
    return $self;
}


sub all_tags {
    my ( $self, @tags ) = @_;
    return unless $self->tags;
    my %tags = map { $_ => 1 } @{ $self->{tags} };
    for my $tag (@tags) {
        return unless $tags{$tag};
    }
    return 1;
}


sub exists_tag {
    my ( $self, @tags ) = @_;
    return unless $self->tags;
    my %tags = map { $_ => 1 } @{ $self->{tags} };
    for my $tag (@tags) {
        return 1 if $tags{$tag};
    }
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::JobLog::Log::Line - encapsulates one line of log text

=head1 VERSION

version 1.042

=head1 DESCRIPTION

B<App::JobLog::Log::Line> encapsulates a line of text from the log -- the semantics of such
a line and the code required to construct, parse, or serialize it.

=head1 METHODS

=head2 new

For composing a log line out of a hash of attributes.

=head2 parse

For parsing a line in an existing log. Expects string to parse as an argument.

=head2 clone

Produces an object semantically identical to that on which it was invoked but
stored without shared references so changes to the latter will not effect the former.

=head2 to_string

Serializes object to the string that would represent it in a log.

=head2 time_stamp

Represents optional L<DateTime> object in the format used in the log. If no
argument is provided, the timestamp of the line itself is returned.

=head2 text

Accessor to text attribute of line, if any. Should only be defined for well formed
log lines. Is lvalue.

=head2 tags

Accessor to array reference containing tags, if any. Is lvalue.

=head2 comment

Accessor to comment value, if any. Should only be defined for comment lines. Is lvalue.

=head2 time

Accessor to time value, if any. Should only be defined for event lines. Lvalue.

=head2 description

Accessor to reference to description list. Should only be defined for lines describing the
beginning of an event. Lvalue.

=head2

Whether lines is malformed.

=head2 is_beginning

Whether line describes the beginning of an event.

=head2 is_end

Whether line only defines the end of an event.

=head2 is_note

Whether the line is a note rather than a terminus of an event or
a comment or blank line.

=head2 is_event

Whether line has a time stamp.

=head2 is_endpoint

Whether the line has a timestamp marking the beginning or end of a logged
interval.

=head2 is_comment

Whether line represents a comment in the log.

=head2 tags_unspecified

Whether object was constructed from a hash of values that contained no C<tags> key.

=head2 is_blank

Whether object represents a blank line in the log.

=head2 comment_out

Convert this into a comment line.

=head2 all_tags

Expects list of tags. Returns whether all tags in list are present in object.

=head2 exists_tag

Expects list of tags. Returns whether any member of list is among tags of object.

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
