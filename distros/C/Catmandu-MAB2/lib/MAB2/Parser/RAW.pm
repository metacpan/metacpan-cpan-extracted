package MAB2::Parser::RAW;

our $VERSION = '0.21';

use strict;
use warnings;
use charnames qw< :full >;
use Carp qw(carp croak);
use Readonly;

Readonly my $LEADER_LEN         => 24;
Readonly my $SUBFIELD_INDICATOR => qq{\N{INFORMATION SEPARATOR ONE}};
Readonly my $END_OF_FIELD       => qq{\N{INFORMATION SEPARATOR TWO}};
Readonly my $END_OF_RECORD      => qq{\N{INFORMATION SEPARATOR THREE}};

sub new {
    my $class = shift;
    my $file  = shift;

    my $self = {
        filename   => undef,
        rec_number => 0,
        reader     => undef,
    };

    # check for file or filehandle
    my $ishandle = eval { fileno($file); };
    if ( !$@ && defined $ishandle ) {
        $self->{filename} = scalar $file;
        $self->{reader}   = $file;
    }
    elsif ( -e $file ) {
        open $self->{reader}, '<:encoding(UTF-8)', $file
            or croak "cannot read from file $file\n";
        $self->{filename} = $file;
    }
    else {
        croak "file or filehande $file does not exists";
    }
    return ( bless $self, $class );
}

sub next {
    my $self = shift;
    if ( my $line = $self->{reader}->getline() ) {
        $self->{rec_number}++;
        my $record = _decode($line);

        # get last subfield from 001 as id
        my ($id) = map { $_->[-1] } grep { $_->[0] =~ '001' } @{$record};
        return { _id => $id, record => $record };
    }
    return;
}

sub _decode {
    my $reader = shift;
    chomp $reader;

    if ( substr( $reader, -1, 1 ) ne $END_OF_RECORD ) {
        carp "record terminator not found";
    }

    my @record;
    my $leader = substr $reader, 0, $LEADER_LEN;
    if ( $leader =~ m/(\d{5}\wM2.0\d*\s*\w)/ ) {
        push @record, [ 'LDR', '', '_', $leader ];
    }
    else {
        carp "faulty record leader: \"$leader\"";
    }

    my @fields = split $END_OF_FIELD, substr( $reader, $LEADER_LEN, -1 );

    for my $field (@fields) {

        if ( length $field <= 4 ) {
            carp "faulty field: \"$field\"";
            next;
        }

        if ( my ( $tag, $ind, $data )
            = $field =~ m/^(\d{3})([A-Za-z0-9\s])(.*)/ )
        {
            if ( $data =~ m/\s*$SUBFIELD_INDICATOR(.*)/ ) {
                push(
                    @record,
                    [   $tag,
                        $ind,
                        map { ( substr( $_, 0, 1 ), substr( $_, 1 ) ) }
                            split /$SUBFIELD_INDICATOR/,
                        $1
                    ]
                );
            }
            else {
                push @record, [ $tag, $ind, '_', $data ];
            }
        }
        else {
            carp "faulty field structure: \"$field\"";
            next;
        }

    }

    return \@record;
}

1;    # End of MAB2::Parser::RAW

__END__

=pod

=encoding UTF-8

=head1 NAME

MAB2::Parser::RAW - MAB2 RAW format parser

=head1 SYNOPSIS

L<MAB2::Parser::RAW> is a parser for raw MAB2 records.

L<MAB2::Parser::RAW> expects UTF-8 encoded files as input. Otherwise provide a 
filehande with a specified I/O layer.

    use MAB2::Parser::RAW;

    my $parser = MAB2::Parser::RAW->new( $filename );

    while ( my $record_hash = $parser->next() ) {
        # do something        
    }

=head1 Arguments

=over

=item C<file>

Path to file with MAB2 Band records.

=item C<fh>

Open filehandle for file with MAB2 Band records.

=back

=head1 METHODS

=head2 new($filename | $filehandle)

=head2 next()

Reads the next record from MAB2 input stream. Returns a Perl hash.

=head2 _decode($record)

Deserialize a raw MAB2 record to an ARRAY of ARRAYs.

=head1 SEEALSO

L<Catmandu::Importer::MAB2>.

=head1 AUTHOR

Johann Rolschewski <jorol@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Johann Rolschewski.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
