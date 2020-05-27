package Data::AnyXfer::Elastic::Test;

use Carp;
use strict;
use warnings;

use Test::Most;
use Perl::Critic::Utils ();


=head1 NAME

 Data::AnyXfer::Elastic::Test - Common elasticsearch tests

=head1 DESCRIPTION

 This module is intended to provide common basic tests for projects which
 utilise L<Data::AnyXfer::Elastic>.

=head1 SYNOSPSIS

Possibly in C<xt/elasticsearch.t>:

    use Data::AnyXfer::Test::Kit;
    use Data::AnyXfer::Elastic::Test ();

    Data::AnyXfer::Elastic::Test->setup_ok('lib');
    done_testing();

=cut

=head1 METHODS

=cut

=head2 setup_ok

    Data::AnyXfer::Elastic::Test->setup_ok('lib');

Currently just tests that indexs contain valid connection values.

=cut

sub setup_ok {

    my ( $class, @dirs_or_files ) = @_;

    # find all perl files and modules
    my @files = Perl::Critic::Utils::all_perl_files(@dirs_or_files);

    # process each file
    note('Standard elasticsearch setup tests');
    SETUP_OK_PERL_FILE: foreach (@files) {

        open( my $file, '<', $_ ) or next;
        while (<$file>) {
            # Find the package name
            if (/^package (.*)::(.*);/) {
                my $pkg = "$1\:\:$2";

                # make sure that we can load the package
                eval { eval("require $pkg") };
                # if there were any errors or the package doesn't contain
                # the Moo meta MOP method, we're not interested
                next SETUP_OK_PERL_FILE if $@ || !$pkg->can('meta');

                # check if this is an index info consumer
                if ($pkg->meta->does_role(
                        q!Data::AnyXfer::Elastic::Role::IndexInfo!)
                    )
                {
                    my $index_info = $pkg->new;
                    like $index_info->silo, qr/^(public_data|private_data)$/,
                        "contains valid silo ($pkg)";
                }

                # XXX: we found the package declaration so move to the next
                # file as we don't support multiple packages within single
                # files
                next SETUP_OK_PERL_FILE;
            }
        }
    }
}

1;

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

