package AlignDB::Stopwatch;
use Moose;

use Time::Duration;
use Data::UUID;
use File::Spec;
use YAML::Syck;

our $VERSION = '1.1.0';

has program_name     => ( is => 'ro', isa => 'Str' );
has program_argv     => ( is => 'ro', isa => 'ArrayRef', default => sub { [] } );
has program_conf     => ( is => 'ro', isa => 'Object' );
has 'start_time'     => ( is => 'rw', isa => 'Value' );
has 'div_char'       => ( is => 'rw', isa => 'Str', default => sub {"="}, );
has 'div_length'     => ( is => 'rw', isa => 'Int', default => sub {30}, );
has 'min_div_length' => ( is => 'rw', isa => 'Int', default => sub {5} );
has uuid             => ( is => 'ro', isa => 'Str' );

sub BUILD {
    my $self = shift;

    $self->{start_time} = time;
    $self->{uuid}       = Data::UUID->new->create_str;

    return;
}

#@returns AlignDB::Stopwatch
sub record {
    my $self = shift;

    $self->{program_name} = $main::0;

    $self->{program_argv} = [@main::ARGV];

    return $self;
}

#@returns AlignDB::Stopwatch
sub record_conf {
    my $self = shift;
    my $conf = shift;

    $self->{program_conf} = $conf;

    return $self;
}

sub _divider {
    my $self  = shift;
    my $title = shift;

    my $title_length = $title ? length $title : 0;

    my $div_char       = $self->div_char;
    my $div_length     = $self->div_length;
    my $min_div_length = $self->min_div_length;

    my $divider_str;

    if ( !$title_length ) {
        $divider_str .= $div_char x $div_length;
        $divider_str .= "\n";
    }
    elsif ( $title_length > $div_length - 2 * $min_div_length ) {
        $divider_str .= $div_char x $min_div_length;
        $divider_str .= $title;
        $divider_str .= $div_char x $min_div_length;
        $divider_str .= "\n";
    }
    else {
        my $left_length = int( ( $div_length - $title_length ) / 2 );
        my $right_length = $div_length - $title_length - $left_length;
        $divider_str .= $div_char x $left_length;
        $divider_str .= $title;
        $divider_str .= $div_char x $right_length;
        $divider_str .= "\n";
    }

    return $divider_str;
}

sub _prompt {
    my $self = shift;
    return "==> ";
}

sub _empty_line {
    my $self = shift;
    return "\n";
}

sub _time {
    my $self  = shift;
    my $title = shift;

    my $time_str;

    if ( !defined $title ) {
        $time_str .= "Current time: ";
    }
    elsif ( $title =~ /start/i ) {
        $time_str .= "Start at: ";
    }
    elsif ( $title =~ /end/i ) {
        $time_str .= "End at: ";
    }
    else {
        $time_str .= "$title: ";
    }
    $time_str .= scalar localtime;
    $time_str .= "\n";

    return $time_str;
}

sub _duration {
    my $self = shift;
    return "Runtime " . $self->duration_now . ".\n";
}

sub _message {
    my $self    = shift;
    my $message = shift;

    $message = '' unless defined $message;

    return $message . "\n";
}

sub duration_now {
    my $self = shift;
    return Time::Duration::duration( time - $self->start_time );
}

sub block_message {
    my $self          = shift;
    my $message       = shift;
    my $with_duration = shift;

    my $text;
    $text .= $self->_empty_line;
    $text .= $self->_prompt;
    $text .= $self->_message($message);
    if ($with_duration) {
        $text .= $self->_prompt;
        $text .= $self->_duration;
    }
    $text .= $self->_empty_line;

    print $text;

    return;
}

sub start_message {
    my $self             = shift;
    my $message          = shift;
    my $embed_in_divider = shift;

    my $text;
    if ( defined $message ) {
        if ( defined $embed_in_divider ) {
            $text .= $self->_divider($message);
        }
        else {
            $text .= $self->_divider;
            $text .= $self->_message($message);
        }
    }
    else {
        $text .= $self->_divider;
    }
    $text .= $self->_time("start");
    $text .= $self->_empty_line;

    print $text;

    return;
}

sub end_message {
    my $self    = shift;
    my $message = shift;

    my $text;
    $text .= $self->_empty_line;
    if ( defined $message ) {
        $text .= $self->_message($message);

    }
    $text .= $self->_time("end");
    $text .= $self->_duration;
    $text .= $self->_divider;

    print $text;

    return;
}

sub cmd_line {
    my $self = shift;
    return join( ' ', $self->program_name, @{ $self->program_argv } );
}

sub init_config {
    my $self = shift;
    return YAML::Syck::Dump $self->program_conf;
}

sub operation {
    my $self = shift;
    my ( undef, undef, $filename ) = File::Spec->splitpath( $self->program_name );
    return $filename;
}

1;

__END__

=head1 NAME

AlignDB::Stopwatch - Record running time and print standard messages

=head1 SYNOPSIS

    use AlignDB::Stopwatch;

    # record command line
    my $stopwatch = AlignDB::Stopwatch->new->record;

    # record config
    $stopwatch->record_conf($opt);

    $stopwatch->start_message("Doing really bad things...");

    $stopwatch->end_message;

=head1 ATTRIBUTES

=head2 program_name

program name

=head2 program_argv

program command line options

=head2 program_conf

program configurations

=head2 start_time

start time

=head2 div_char

Divider char used in output messages, default is [=]

=head2 div_length

Length of divider char, default is [30]

=head2 min_div_length

minimal single-side divider length, default is [5]

=head2 uuid

Use Data::UUID to generate a UUID that prevent inserting meta info more than
one time on multithreads mode

=head1 METHODS

=head2 record

Record $main::0 to program_name and [@main::ARGV] to program_argv.

Getopt::Long would manipulate @ARGV.

    my $stopwatch = AlignDB::Stopwatch->new->record;

=head2 record_conf

Record a hashref or object to program_conf.

    $stopwatch->record_conf( $opt );

=head2 block_message

Print a blocked message

    $stopwatch->block_message( $message, $with_duration );

=head2 start_message

Print a starting message

    $stopwatch->start_message( $message, $embed_in_divider );

=head2 end_message

Print a ending message

    $stopwatch->end_message( $message );

=head1 AUTHOR

Qiang Wang <wang-q@outlook.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008- by Qiang Wang.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
