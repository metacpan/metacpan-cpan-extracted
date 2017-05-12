#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More 'no_plan';

use Archive::Any;
use File::Spec::Functions qw(updir);

my %tests = (
  't/lib.tar.bz2' => {
      impolite=> 0,
      naughty => 0,
      handler => 'Archive::Any::Plugin::Bzip2',
      type    => 'tar',
      files   => [qw(
        lib/
        lib/Archive/
        lib/Archive/Any/
        lib/Archive/Any/Plugin/
        lib/Archive/Any/Plugin/Bzip2.pm
        )],
  },
);

while( my($file, $expect) = each %tests ) {
    # Test it once with type auto-discover and once with the type
    # forced.  Forced typing was broken until 0.05.
    test_archive($file, $expect);
    test_archive($file, $expect, $expect->{type});
}

sub test_archive {
    my($file, $expect, $type) = @_;

    my $archive = Archive::Any->new($file, $type);

    # And now we chdir out from under it.  This causes serious problems
    # if we're not careful to use absolute paths internally.
    chdir('t');

    ok( defined $archive,               "new($file)" );
    ok( $archive->isa('Archive::Any'),  "  it's an object" );

    ok( eq_set([$archive->files], $expect->{files}),
                                     '  lists the right files' );
    ok( $archive->type(), "backwards compatibility" );

#    is( $archive->handler, $expect->{handler},    '  right handler' );

    is( $archive->is_impolite, $expect->{impolite},  "  impolite?" );
    is( $archive->is_naughty,  $expect->{naughty},   "  naughty?" );

    unless( $archive->is_impolite || $archive->is_naughty ) {
        ok($archive->extract(),   "extract($file)");
        foreach my $file (reverse $archive->files) {
            ok( -e $file, "  $file" );
            -d $file ? rmdir $file : unlink $file;
        }
    }

    chdir(updir);
}
