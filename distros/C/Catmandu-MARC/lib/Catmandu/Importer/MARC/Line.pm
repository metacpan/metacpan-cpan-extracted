=head1 NAME

Catmandu::Importer::MARC::Line - Package that imports Index Data's MARC Line records

=head1 SYNOPSIS

    # From the command line
    $ catmandu convert MARC --type Line --fix 'marc_map("245a","title")' < t/code4lib.line
    $ catmandu convert MARC --type Line to MARC --type XML < t/code4lib.line


    # From perl
    use Catmandu;

    # import records from file
    my $importer = Catmandu->importer('MARC',file => 't/code4lib.line' , type => 'Line');
    my $fixer    = Catmandu->fixer("marc_map('245a','title')");

    $importer->each(sub {
        my $item = shift;
        ...
    });

    # or using the fixer

    $fixer->fix($importer)->each(sub {
        my $item = shift;
        printf "title: %s\n" , $item->{title};
    });

=head1 CONFIGURATION

=over

=item file

Read input from a local file given by its path. Alternatively a scalar
reference can be passed to read from a string.

=item fh

Read input from an L<IO::Handle>. If not specified, L<Catmandu::Util::io> is used to
create the input stream from the C<file> argument or by using STDIN.

=item encoding

Binmode of the input stream C<fh>. Set to C<:utf8> by default.

=item fix

An ARRAY of one or more fixes or file scripts to be applied to imported items.

=back

=head1 METHODS

Every Catmandu::Importer is a Catmandu::Iterable all its methods are inherited.

=head1 AUTHOR

Johann Rolschewski,  E<lt>jorol at cpanE<gt>

=head1 SEE ALSO

L<Catmandu::Importer>,
L<Catmandu::Iterable>

=cut

package Catmandu::Importer::MARC::Line;
use Catmandu::Sane;
use Moo;

our $VERSION = '1.281';

with 'Catmandu::Importer';

sub generator {
    my ($self) = @_;
    sub {
        state $fh    = $self->fh;
        state $count = 0;

        # set input record separator to paragraph mode
        local $/ = '';

        # get next record
        while (defined(my $data = $fh->getline)) {
            $count++;
            my @record;
            my $id;
            chomp $data;

            # split record into fields
            my @fields = split /\n/, $data;

            # first field should be the MARC leader
            my $leader = shift @fields;
            if (length $leader == 24 && $leader =~ m/^\d{5}.*4500/) {
                push @record, ['LDR', ' ', ' ', '_', $leader];
            } else {
                warn "not a valid MARC leader: $leader";
            }
            for my $field (@fields) {

                # process control fields
                if ($field =~ m/^00.\s/) {
                    my ($tag, $value) = $field =~ m/^(\d{3})\s(.*)/;
                    push @record, [$tag, ' ', ' ', '_', $value];

                    # get record id
                    if ($tag eq '001') {
                        $id = $value;
                    }
                }

                # process variable data fields
                else {
                    my ($tag, $ind1, $ind2, $sf)
                        = $field =~ m/^(\d{3})\s([a-z0-9\s])([a-z0-9\s])\s(.*)/;

                    # check if field has content
                    if ($sf) {
                        # get subfield codes by pattern
                        # some special characters are allowed as subfiled codes in local defined field
                        # see https://www.loc.gov/marc/96principl.html#eight 8.4.2.3.
                        my @sf_codes = $sf =~ m/\s?\$([a-z0-9!"#\$%&'\(\)\*\+'-\.\/:;<=>])\s/g;

                        # split string by subfield code pattern
                        my @sf_values
                            = grep {length $_}
                                split
                                /\s?\$[a-z0-9!"#\$%&'\(\)\*\+'-\.\/:;<=>]\s/,
                                $sf;
                           
                        if (scalar @sf_codes != scalar @sf_values) {
                            warn
                                'different number of subfield codes and values';
                            next;
                        }

                        push @record,
                            [
                            $tag,  $ind1,
                            $ind2, map {$_, shift @sf_values} @sf_codes
                            ];
                    }

                    # skip empty fields
                    else {
                        warn "field $tag has no content";
                        next;
                    }

                }
            }
            return {_id => defined $id ? $id : $count, record => \@record};
        }
        return;
    };
}

1;
