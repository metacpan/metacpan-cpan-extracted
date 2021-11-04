#!perl -w
use strict;
use warnings;

=head1 NAME

dependencies.t - Checks that all required CPAN modules are enumerated in B<Build.PL>.

=cut

use Test2::V0;
use File::Find::Rule::Perl;
use Test::Dependencies;
use CPAN::Meta;

=head1 HACKS

=head2 C<Test::Dependencies::_get_modules_used_in_file()>

Changed so as to detect `require` statements (for some reason, the
original implementation overlooks that part)

=cut

no warnings "redefine";
*Test::Dependencies::_get_modules_used_in_file = sub  {
    my $file = shift;
    my ($fh, $code);
    my %used;

    local $/;
    open $fh, $file or return undef;
    my $data = <$fh>;
    close $fh;
    my $p = Pod::Strip->new;
    $p->output_string(\$code);
    $p->parse_string_document($data);
    $used{$2}++ while $code =~ /^\s*(use|with|extends|require)\s+['"]?([\w:.]+)['"]?/gm;
    while ($code =~ m{^\s*use\s+base
                          \s+(?:qw.|(?:(?:['"]|q.|qq.)))([\w\s:]+)}gmx) {
        $used{$_}++ for split ' ', $1;
    }

    return [keys %used];
};

my $meta = CPAN::Meta->load_file('META.yml');
my @files = grep { ! m|t/maintainer/| }
  (File::Find::Rule::Perl->perl_file->in(qw(Build.PL ./lib ./t ./inc)));
ok_dependencies($meta, \@files,
                forward_compatible => 1,
                ignores => [qw(Crypt::OpenSSL::CA
                               My::Tests::Below My::Module::Build
                               Fake::Module
                               the)]);  # “use the“ appears in the code,
                                        # or rather in a comment, I guess?
                                        # Whatever

done_testing;
