use warnings;
use strict;

use Test::More;
use File::Find;

my $boilerplate_headings = q{
=head1 FURTHER QUESTIONS?

Check the list of L<additional DBIO resources|DBIO/GETTING HELP/SUPPORT>.

=head1 COPYRIGHT AND LICENSE

This module is free software L<copyright|DBIO/COPYRIGHT AND LICENSE>
by the L<DBIO authors|DBIO/AUTHORS>. You can
redistribute it and/or modify it under the same terms as the
L<DBIO library|DBIO/COPYRIGHT AND LICENSE>.
};

find({
  wanted => sub {
    my $fn = $_;

    return unless -f $fn;
    return unless $fn =~ / \. (?: pm | pod ) $ /ix;

    my $data = do { local (@ARGV, $/) = $fn; <> };

    if ($data !~ /^=head1 NAME/m) {

      # the generator is full of false positives, .pod is where it's at
      return if $fn =~ qr{\Qlib/DBIO/Optional/Dependencies.pm};

      ok ( $data !~ /\bcopyright\b/i, "No copyright notices in $fn without apparent POD" );
    }
    elsif ($fn =~ qr{\Qlib/DBIO.}) {
      # nothing to check there - a static set of words
    }
    else {
      ok ( $data !~ / ^ =head1 \s $_ /xmi, "No standalone $_ headings in $fn" )
        for qw(AUTHOR CONTRIBUTOR LICENSE LICENCE);

      ok ( $data !~ / ^ =head1 \s COPYRIGHT \s (?! AND \s LICENSE )/xmi, "No standalone COPYRIGHT headings in $fn" );

      ok ($data =~ / \Q$boilerplate_headings\E (?! .*? ^ =head )/xms, "Expected headings found at the end of $fn");
    }
  },
  no_chdir => 1,
}, (qw(lib examples)) );

done_testing;
