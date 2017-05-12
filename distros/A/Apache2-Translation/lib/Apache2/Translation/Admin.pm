package Apache2::Translation::Admin;

use 5.008008;
use strict;
use warnings;
no warnings qw(uninitialized);

use Apache2::RequestRec;
use Apache2::RequestUtil;
use Apache2::RequestIO;
use Apache2::ServerRec;
use Apache2::ServerUtil;
use Apache2::Connection;
use Apache2::Log;
use Apache2::SubRequest;
use Apache2::Filter;
use APR::Brigade;
use APR::Bucket;
use APR::Table;
use APR::Socket;
use Apache2::Const -compile=>qw{:common :http};
use Apache2::Request;

use Template;
use Class::Member::HASH -CLASS_MEMBERS=>qw/static types types_re templates
					   tt provider provider_url
					   provider_spec r title/;
our @CLASS_MEMBERS;

our $VERSION = '0.06';
our $STATIC;
our $DEFAULTPROVIDERHOST='http://localhost';

$STATIC=__PACKAGE__;
$STATIC=~s!::!/!g;
$STATIC=$INC{$STATIC.'.pm'};
$STATIC=~s/\.pm$//;

our %TYPES=
  (
   gif=>'image/gif',
   png=>'image/png',
   jpg=>'image/jpeg',
   jpeg=>'image/jpeg',
   ico=>'image/x-icon',
   html=>'text/html',
   shtml=>'text/html',
   css=>'text/css',
   js=>'application/x-javascript',
  );

sub _config_provider_SPEC {
  my ($I)=@_;

  my $param=$I->provider_spec;
  my $class=$param->[0];
  eval "use Apache2::Translation::$class;";
  if( $@ ) {
    warn "ERROR: Cannot use Apache2::Translation::$class: $@" if $@;
    eval "use $class;";
    die "ERROR: Cannot use $class: $@" if $@;
  } else {
    $class='Apache2::Translation::'.$class;
  }
  $I->provider=$class->new( @{$param}[1..$#{$param}] );
  local $"='; ';
  my %x=@{$param}[1..$#{$param}];
  $I->title="($param->[0]: @{[map qq{$_=$x{$_}}, keys %x]})";
}

sub _fetch_provider_LWP {
  my ($I)=@_;

  require LWP::UserAgent;

  my $ua=LWP::UserAgent->new;
  my $resp=$ua->get($I->provider_url);
  if( $resp->is_success ) {
    my $x;
    unless( eval 'require JSON::XS' and
	    $x=eval {JSON::XS::decode_json($resp->content)} ) {
      eval 'require YAML' and $x=eval {YAML::Load($resp->content)};
    }
    if( ref($x) eq 'HASH' and exists $x->{TranslationProvider} ) {
      $I->provider_spec=$x->{TranslationProvider};
      $I->_config_provider_SPEC;
      $I->title="@ ".$I->provider_url;
    }
  }
}

sub new {
  my $parent=shift;
  my $I=bless {}, ref($parent)?ref($parent):$parent;
  my %o=@_;

  # set defaults
  $I->static=$STATIC;
  $I->templates=$STATIC.'/templates';
  $I->types={};

  # then override with named parameters
  foreach my $m (@CLASS_MEMBERS) {
    $I->$m=$o{$m} if( exists $o{$m} );
  }
  @{$I->types}{keys %TYPES}=values %TYPES;
  my $re=join '|', keys %{$I->types};
  $I->types_re=qr/$re/;

  unless( defined $I->tt and ref $I->tt and $I->tt->isa('Template') ) {
    $I->tt=Template->new({
			  INCLUDE_PATH=>$I->templates,
			  EVAL_PERL=>1,
			 })
      or die "ERROR: While creating template object: $Template::ERROR\n";
  }

  unless( ref $I->provider ) {
    if( length $I->provider_url ) {
      $I->provider_url=$DEFAULTPROVIDERHOST.$I->provider_url
	unless( $I->provider_url=~m!^\w+:! );
    } elsif( ref($I->provider_spec) eq 'ARRAY' ) {
      $I->_config_provider_SPEC;
    } elsif( length $INC{'Apache2/Translation.pm'} and defined $I->r ) {
      $I->provider=(Apache2::Module::get_config('Apache2::Translation',
						$I->r->server) || {})
	->{provider};
      $I->title="@ ".$I->r->server->server_hostname;
    }

    unless( length $I->provider_url ) {
      die "ERROR: Cannot resolve translation provider\n"
	unless(ref $I->provider);
    }
  }

  return $I;
}

sub xindex {
  my ($I, $r)=@_;

  my $prov=$I->provider;
  my $stash={q=>$r, I=>$I};
  $prov->start;

  my $key=$r->param('key');
  my @l;
  {
    no re 'eval';
    my $k=$key;
    $k='.' unless( length $k );
    $k=eval {qr/$k/};
    unless( defined $k ) {
      $k=qr/./;
      $key='';
    }
    eval {
      local $SIG{ALRM}=sub { die "__ALRM__\n"; };
      alarm 5;
      eval {
	@l=grep {$_->[0]=~/$k/} $prov->list_keys_and_uris;
      };
      alarm 0;
    };
    alarm 0;

    if( $@ ) {
      @l=$prov->list_keys_and_uris;
      $key='';
    }
  }

  $stash->{PREPROC}=[grep {$_->[1] eq ':PRE:'} @l];
  $stash->{LOOKUPFILE}=[grep {$_->[1] eq ':LOOKUPFILE:'} @l];
  $stash->{URIS}=[grep {$_->[1]=~m!^/!} @l];
  $stash->{SUBS}=[grep {$_->[1]!~m!^(?:/|:PRE:$|:LOOKUPFILE:$)!} @l];
  $stash->{KEY}=$key;

  $prov->stop;

  my $menu=$r->uri;
  $menu=~s!/[^/]*$!/menu.html!;
  my $subr=$r->lookup_uri($menu);
  $subr->add_output_filter( sub {
			      my ($f, $bb) = @_;
			      while (my $e = $bb->first) {
				$e->read(my $buf);
				$menu.=$buf;
				$e->delete;
			      }
			      return Apache2::Const::OK;
			    });
  $menu='';
  if( $subr->status==Apache2::Const::HTTP_OK ) {
    $subr->run;
    $menu='' unless( $subr->status==Apache2::Const::HTTP_OK );
  }
  $stash->{MENU}=$menu;

  $I->tt->process('index.html', $stash, $r)
    or do {
      my $err=$I->tt->error;
      $r->log_reason($err);
      $err=~s/[\0-\37\177-\377]/ /g;
      $r->err_headers_out->{'X-Error'}=$err;
      return Apache2::Const::SERVER_ERROR;
    };

  return Apache2::Const::OK;
}

sub xfetch {
  my ($I, $r, $key, $uri)=@_;

  my $prov=$I->provider;
  my $stash={q=>$r, I=>$I};
  $prov->start;

  my @l;
  my $block;
  my $current;
  $key=$r->param('key') unless( defined $key );
  $stash->{key}=$key;
  $uri=$r->param('uri') unless( defined $uri );
  $stash->{uri}=$uri;

  my $rowspan;
  foreach my $el ($prov->fetch( $key, $uri, 1 )) {
    if( $block ne $el->[0] ) {
      $block=$el->[0];
      $current={ b=>$block, a=>[] };
      push @l, $current;
    }
    $el->[2]=~s/^\s+//;
    $el->[2]=~s/\s+$//;
    my $extra_style="";
    if( $r->param("ysize_${block}_$el->[1]")=~/(\d+)/ ) {
      $extra_style=" style=\"height: ${1}px\"";
    }
    push @{$current->{a}}, +{
			     o=>$el->[1],
			     a=>$el->[2],
			     id=>$el->[3]||'',
			     c=>$el->[4]||'',
			     extra_style=>$extra_style,
			    };
  }
  $stash->{BL}=\@l;

  $prov->stop;

  unless( @l ) {
    my $err="ERROR: Blocklist empty for (Key: $key, Uri: $uri)";
    $err=~s/[\0-\37\177-\377]/ /g;
    $r->log_reason($err);
    $r->err_headers_out->{'X-Error'}=$err;
    $r->err_headers_out->{'X-ErrorCode'}=1;
    return Apache2::Const::SERVER_ERROR;
  }

  $I->tt->process('fetch.html', $stash, $r)
    or do {
      my $err=$I->tt->error;
      $r->log_reason($err);
      $err=~s/[\0-\37\177-\377]/ /g;
      $r->err_headers_out->{'X-Error'}=$err;
      return Apache2::Const::SERVER_ERROR;
    };

  return Apache2::Const::OK;
}

sub xupdate {
  my ($I, $r)=@_;

  my $prov=$I->provider;
  my $stash={q=>$r, I=>$I};
  my ($okey, $key, $ouri, $uri)=map {$r->param($_)} qw/key newkey
						       uri newuri/;
  $prov->start;

 RETRY: {
    eval {
      $prov->begin;

      my ($oblock, $block, $oorder, $order, $id, $action, $note);
      foreach my $a ($r->param) {
	if( ($oblock, $block, $oorder, $order, $id)=
	    $a=~/^action_(\d*)_(\d+)_(\d*)_(\d+)_(\d*)/ ) {
	  $action=$r->param($a);
	  $note=$r->param("note_${block}_${order}");
	  if( length $id ) {
	    die "ERROR: Key=$okey, Uri=$ouri, Block=$oblock, Order=$oorder, Id=$id not updated\n"
	      unless( 0<$prov->update( [$okey, $ouri, $oblock, $oorder, $id],
				       [$key, $uri, $block, $order, $action, $note] ) );
	  } else {
	    die "ERROR: Key=$key, Uri=$uri, Block=$block, Order=$order not inserted\n"
	      unless( 0<$prov->insert( [$key, $uri, $block, $order, $action, $note] ) );
	  }
	} elsif( ($oblock, $oorder, $id)=
		 $a=~/^delete_(\d*)_(\d+)_(\d*)/ ) {
	  die "ERROR: Key=$okey, Uri=$ouri, Block=$oblock, Order=$oorder, Id=$id not deleted\n"
	    unless( 0<$prov->delete( [$okey, $ouri, $oblock, $oorder, $id] ) );
	}
      }

      $prov->commit
    };

    if($@) {
      if( $@ eq "__RETRY__\n" ) {
	$prov->rollback;
	redo RETRY;
      }
      $r->log_reason( "$@" );
      my $err="$@";
      $err=~s/[\n\0-\37\177-\377]/ /g;
      $r->err_headers_out->{'X-Error'}=$err;

      $prov->rollback;
      $prov->stop;

      $key=$okey;
      $uri=$ouri;

      return Apache2::Const::SERVER_ERROR;
    }
  }

  $prov->stop;

  return $I->xfetch($r, $key, $uri);
}

sub handler : method {
  my ($I, $r)=@_;

  unless( ref($I) ) {
    $I=$I->new(r=>$r);
  }

  my $uri=$r->uri;
  $uri=~s!^.*/!/!;

  unless( $uri eq '/' or $uri eq '/index.html' ) {
    my $f=$I->static.$uri;
    return Apache2::Const::NOT_FOUND unless( -f $f and -r _ );
    my $re=$I->types_re;
    if( $f=~m!\.($re)$!i ) {
      $r->content_type($I->types->{lc $1});
    } else {
      $r->content_type('text/plain');
    }
    $r->sendfile($f);
    return Apache2::Const::OK;
  }

  unless( defined $I->provider ) {
    $I->_fetch_provider_LWP if(length $I->provider_url);
    die "ERROR: Cannot resolve translation provider\n"
      unless(ref $I->provider);
  }

  $r=Apache2::Request->new($r);

  $r->content_type('text/html; charset=UTF-8');

  my $a=$r->param('a');
  if( $a eq '' ) {
    return $I->xindex($r);
  } elsif( $a eq 'fetch' ) {
    return $I->xfetch($r);
  } elsif( $a eq 'update' ) {
    return $I->xupdate($r);
  } else {
    return Apache2::Const::NOT_FOUND;
  }

  return Apache2::Const::OK;
}

1;

__END__
