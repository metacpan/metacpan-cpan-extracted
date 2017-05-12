#!/usr/bin/perl
use File::Find;

my @dirs = @ARGV or die "$0 /path/to/your/MyPageKit";
my ( @tmpl_files, @myModel_files, %found_in);

@ARGV = ();

find( sub {
    return unless -f;

    /^Common\.pm$/  && push @ARGV,          $File::Find::name;
    /^MyModel\.pm$/ && push @myModel_files, $File::Find::name;
    /\.tmpl$/       && push @tmpl_files,    $File::Find::name;
  },
  @dirs
);

$^I = '.bak';

if (@ARGV) {
  while (<>) {
    if (s/\$__PACKAGE__::secret_md5/\${ __PACKAGE__ . '::secret_md5' }/) {
      my ($i) = /(\s*)/;
      $_ = $i . "no strict 'refs';\n" . $_ . $i . "use strict 'refs';\n";
    }

    # remove Digest::MD5
    next if ( /^\s*use\s+Digest::MD5\b/ );

    # add Digest::MD5 after DBI and hopefully before MyPageKit::MyModel
    if ( !exists $found_in{$ARGV} and /^\s*use\s+DBI\b/) {
      $found_in{$ARGV} = 1;
      $_ = "use Digest::MD5 ();\n$_";
    }

    #
    s/Digest::MD5->md5_hex/Digest::MD5::md5_hex/;

    print;
  }
}

*ARGV = \@myModel_files;

if (@ARGV) {
  while (<>) {
    s/MD5->hexhash/Digest::MD5::md5_hex/g;
    print;
  }
}


*ARGV = \@tmpl_files;

if (@ARGV) {
  while (<>) {
    s!<\s*PKIT_COMPONENT\s+(\w+)\s*/?>!<PKIT_COMPONENT NAME="$1"/>!ig;
    print;
  }
}
