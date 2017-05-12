package Apache2::Translation::Config;

use 5.008;
use strict;
use warnings;
no warnings qw(uninitialized);

use Apache2::RequestRec;
use Apache2::RequestIO;
use Apache2::Module;
use attributes;
use Apache2::Const -compile=>qw{OK};

our $VERSION='0.01';

sub handler {
  my $r=shift;

  my $cf=Apache2::Module::get_config('Apache2::Translation', $r->server);

  $r->content_type('text/plain');

  my $cache=$cf->{eval_cache};
  if( tied %{$cache} ) {
    $cache=tied( %{$cache} )->max_size;
  } else {
    $cache='unlimited';
  }

  my $args=lc $r->args;
  if( $args ne 'yaml' and eval 'require JSON::XS' ) {
    $r->print( JSON::XS::encode_json
	       ( {
		  TranslationKey=>$cf->{key},
		  TranslationProvider=>$cf->{provider_param},
		  TranslationEvalCache=>$cache,
		 } ) );
  } elsif( eval 'require YAML' ) {
    $r->print( YAML::Dump
	       ( {
		  TranslationKey=>$cf->{key},
		  TranslationProvider=>$cf->{provider_param},
		  TranslationEvalCache=>$cache,
		 } ) );
  } else {
    die "Please install JSON::XS or YAML";
  }

  return Apache2::Const::OK;
}

1;
__END__
