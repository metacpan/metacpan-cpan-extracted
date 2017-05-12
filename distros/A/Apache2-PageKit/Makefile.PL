
#
#
#

package XXMY;
sub postamble {
  local $_ = $ExtUtils::MakeMaker::VERSION;
  y/_//d;
  my $pre = $_ <= 6.21 
    ? qq{patch_blib: pm_to_blib\n}
    : qq{patch_blib: patch_blib.ts\npatch_blib.ts: pm_to_blib.ts\n};
  return $pre . <<'ENDE';
	@$(TOUCH) $@

ENDE
}

sub top_targets {
  my $t = shift->SUPER::top_targets(@_);
  if ( $] >= 5.008 ) {
    $t =~ s!pure_all :: config pm_to_blib!pure_all :: config!;
  }
  $t;
}
1;


package main;
require ModPerl::MM;

#

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

###########################################
# install_checker, contrib by Boris Zentner

##use vars qw( %Requirements %Recommended %Example );

use vars qw( %h );

%h = (
  '5.008' => {

    # version is the minimum version required to run

    Requirements => {
                      'Apache::Test'          => { version => 1.05 },
                      'Apache::SessionX'      => {},
                      'Compress::Zlib'        => {},
                      'Data::FormValidator'   => {},
                      'Digest::MD5'           => {},
                      'HTML::FillInForm'      => { version => 0.12 },
                      'HTML::Template'        => { version => 2.2 },
                      'HTML::Template::XPath' => { version => 0.10 },
                      'HTML::Clean'           => {},
                      'Encode'                => {},
                      'XML::LibXML' => { version => 1.53, comment => '(you need libxml2 >= 2.4.10 and libxslt >= 1.0.9)' },
    },

    Recommended => {
                    'Mail::Mailer' => { comment => '(only needed if you use Apache::ErrorReport)' },
                    'Apache::DBI'  => { comment => '(*strongly* recommended if you use DBI)' },
                    'MIME::Types' => { comment => '(needed if you want to serve static files from View/Default directory)' },
                    'XML::LibXSLT' => { version => 1.53, comment => '(needed if you want to use XSLT tranformations)' },
                    'Storable'        => { version => 1.013, comment => '(needed for heavy loaded servers)' },
                    'Locale::gettext' => { version => 1.01,  comment => '(needed if you want to localize pkit messages)' },
    },

    Example => {
                 'DBD::SQLite'    => {},
                 'HTTP::Headers'  => {},
                 'Apache2::Reload' => {},
    }
  },
);

#insert _name and _installed_version into the hash(s)
sub init {
  my $mods_ref = shift;
  for ( keys %$mods_ref ) {
    $mods_ref->{$_}{_name} = $_;
    eval {
      no strict "refs";
      ( my $fname = $_ ) =~ s!::!/!g;
      require "${fname}.pm";

      my $version = "$_" . "::VERSION";
      if ( defined $$version ) {
        $mods_ref->{$_}{_installed_version} = $$version;
      }
      else {

        # module installed, but no $VERSION var
        $mods_ref->{$_}{_installed_version} = 0;
      }
    };
    if ($@) {
      unless ( $@ =~ m!^Can't locate \S+ in \@INC! ) {

        # assume module can't be loaded outside of mod_perl (e.g. Apache::DBI)
        $mods_ref->{$_}{_installed_version} = 0;
      }
    }
  }
}

sub show_versions {
  my @hrefs = @_;
  my @res   = ();
  my $len   = 0;
  for my $href (@hrefs) {
    for ( keys %$href ) {
      if ( defined( $href->{$_}{_installed_version} ) ) {
        $len = length if length > $len;
        push @res, $href->{$_};
      }
    }
  }

  if (@res) {
    for ( sort { $a->{_name} cmp $b->{_name} } @res ) {
      printf "  %-${len}s %6s %s\n", $_->{_name}, $_->{_installed_version}, $_->{comment} || '';
    }
  }
}

sub check_mods {
  my $title_install = shift;
  my $title_update  = shift;
  my @install       = ();
  my @update        = ();
  my $ilen          = 0;
  my $ulen          = 0;

  for my $href (@_) {
    for ( keys %$href ) {
      if ( !defined $href->{$_}{_installed_version} ) {
        $ilen = length if ( length > $ilen );
        push @install, $href->{$_};
      }
      elsif (    defined $href->{$_}{_installed_version}
              && defined $href->{$_}{version}
              && $href->{$_}{_installed_version} < $href->{$_}{version} ) {
        $ulen = length if ( length > $ulen );
        push @update, $href->{$_};
      }
    }
  }

  if (@install) {
    print "$title_install\n";
    for ( sort { $a->{_name} cmp $b->{_name} } @install ) {
      printf "  %-${ilen}s %s\n", $_->{_name}, $_->{comment} || '';
    }
  }

  if (@update) {
    print "$title_update\n";
    for ( sort { $a->{_name} cmp $b->{_name} } @update ) {
      printf "  %-${ulen}s (%s) to at least %s %s\n", $_->{_name}, $_->{_installed_version}, $_->{version},
        $_->{comment} || '';
    }
  }
}

my @versions = sort keys(%h);
my $vers     = $versions[0];
for (@versions) {
  if ( $] >= $_ ) {
    $vers = $_;
  }
  else {
    last;
  }
}

init($_) for ( $h{$vers}{Requirements}, $h{$vers}->{Recommended}, $h{$vers}{Example} );
my $update = 'Please update the following module(s):';
check_mods( "You need to install the following module(s) to run PageKit:\n", $update, $h{$vers}{Requirements} );
check_mods( "\nYou should install the following module(s) to run PageKit:\n",  $update, $h{$vers}{Recommended} );
check_mods( "\nYou need to install the following module(s) to run the PageKit Example Server:\n", $update, $h{$vers}{Example} );
print "\n";

# end install_checker
###################################

use lib qw;t;;
use Apache::Test 1.05;
use Apache::TestMM qw/test clean/;

Apache::TestMM::filter_args();
Apache::TestMM::generate_script('t/TEST');

my $prereq_pm = {
                   'Apache::Test'          => 1.05,
                   'Apache2::URI'           => 0,
#                   'Apache2::Cookie'        => 0,
#                   'Apache2::Request'       => 0,
                   'Apache::SessionX'      => 0,
                   'Apache2::Util'          => 0,
                   'Compress::Zlib'        => 0,
                   'Data::FormValidator'   => 0,
                   'HTML::Clean'           => 0,
                   'HTML::FillInForm'      => 0.12,
                   'HTML::Template'        => 2.2,
                   'HTML::Template::XPath' => 0.10,
                   'Encode'                => 0,
                   'XML::LibXML'           => 1.53,
                   mod_perl2                => 2
  };

ModPerl::MM::WriteMakefile(
  'NAME'         => 'Apache2::PageKit',
  'AUTHOR'       => 'T.J. Mather <tjmather\@thoughtstore.com>',
  'VERSION_FROM' => 'lib/Apache2/PageKit.pm',                                                          # finds $VERSION
  'clean'        => { FILES => "t/TEST t/httpd t/error_log eg/View/pkit_cache/* eg/conf eg/htdocs eg/logs patch_blib" },
  'PREREQ_PM'    => $prereq_pm
);

