package Bot::Cobalt::Plugin::Extras::CPAN;
$Bot::Cobalt::Plugin::Extras::CPAN::VERSION = '0.021003';
use strictures 2;

use Bot::Cobalt;
use Bot::Cobalt::Common;

use Bot::Cobalt::Serializer;
our $Serializer = Bot::Cobalt::Serializer->new('JSON');

use HTTP::Request;

use Module::CoreList;

use Try::Tiny;

our $HelpText
  = 'try: dist, latest, tests, abstract, changes, belongs, license';

## FIXME cachedb?

sub new { bless [], shift }

sub Cobalt_register {
  my ($self, $core) = splice @_, 0, 2;

  register $self, SERVER => qw/
    public_cmd_cpan
    public_cmd_corelist
    mcpan_plug_resp_recv
  /;

  logger->info("Loaded: !cpan");

  PLUGIN_EAT_NONE
}

sub Cobalt_unregister {
  my ($self, $core) = splice @_, 0, 2;
  logger->info("Bye!");
  PLUGIN_EAT_NONE
}

sub Bot_public_cmd_corelist {
  my ($self, $core) = splice @_, 0, 2;
  my $msg = ${ $_[0] };

  my $dist = $msg->message_array->[0];

  unless ($dist) {
    broadcast( 'message',
      $msg->context, $msg->channel,
      "corelist needs a module name."
    );
    return PLUGIN_EAT_ALL
  }

  my $resp;
  my $vers = $msg->message_array->[1];
  if (my $first = Module::CoreList->first_release($dist, $vers)) {
    $resp = $vers ?
            "$dist ($vers) was released with $first"
            : "$dist was released with $first"
  } else {
    $resp = "Module not found in core."
  }

  broadcast( 'message',
    $msg->context, $msg->channel,
    join(', ', $msg->src_nick, $resp)
  );
}

sub Bot_public_cmd_cpan {
  my ($self, $core) = splice @_, 0, 2;
  my $msg = ${ $_[0] };

  my ($cmd, $dist) = @{ $msg->message_array };

  unless ($cmd) {
    broadcast( 'message',
      $msg->context, $msg->channel,
      "No command; $HelpText"
    );
    return PLUGIN_EAT_ALL
  }

  unless ($dist) {
    # assume 'abstract' if only one arg
    $dist = $cmd;
    $cmd  = 'abstract';
  }

  $cmd = lc $cmd;
  $dist =~ s/::/-/g
    unless $cmd eq "belongs"
    or     $cmd eq "changes";
  my $url = "/release/$dist";

  my $hints = +{
    Context => $msg->context,
    Channel => $msg->channel,
    Nick    => $msg->src_nick,
    Dist    => $dist,
    Link    => "http://www.metacpan.org${url}",
  };

  CMD: {
    if ($cmd eq 'latest' || $cmd eq 'release') {
      $hints->{Type} = 'latest';
      last CMD
    }

    if ($cmd eq 'dist') {
      $hints->{Type} = 'dist';
      last CMD
    }

    if ($cmd eq 'test' || $cmd eq 'tests') {
      $hints->{Type} = 'tests';
      last CMD
    }

    if ($cmd eq 'info' || $cmd eq 'abstract') {
      $hints->{Type} = 'abstract';
      last CMD
    }

    if ($cmd eq 'license') {
      $hints->{Type} = 'license';
      last CMD
    }

    if ($cmd eq 'belongs') {
      $hints->{Type} = 'belongs';
      $url = "/module/$dist";
      last CMD
    }

    if ($cmd eq 'changes') {
      $hints->{Type} = 'changes';
      $url = "/module/$dist";
      last CMD
    }

    broadcast( 'message', $msg->context, $msg->channel,
      "Unknown query; $HelpText"
    );
  }

  $self->_request($url, $hints) if defined $hints->{Type};

  PLUGIN_EAT_ALL
}

sub _request {
  my ($self, $url, $hints) = @_;

  my $base_url = 'http://api.metacpan.org';
  my $this_url = $base_url . $url;

  logger->debug("metacpan request: $this_url");

  my $request = HTTP::Request->new(GET => $this_url);

  broadcast( 'www_request',
    $request,
    'mcpan_plug_resp_recv',
    $hints
  );
}

sub Bot_mcpan_plug_resp_recv {
  my ($self, $core) = splice @_, 0, 2;
  my $response = ${ $_[1] };
  my $hints    = ${ $_[2] };

  my $dist = $hints->{Dist};
  my $type = $hints->{Type};
  my $link = $hints->{Link};

  unless ($response->is_success) {
    my $status = $response->code;
    if ($status == 404) {
      broadcast( 'message',
        $hints->{Context}, $hints->{Channel},
        "No such distribution: $dist"
      );
    } else {
      broadcast( 'message',
        $hints->{Context}, $hints->{Channel},
        "Could not get release info for $dist ($status)"
      );
    }
    return PLUGIN_EAT_ALL
  }

  my $json = $response->content;
  unless ($json) {
    broadcast('message',
      $hints->{Context}, $hints->{Channel},
      "Unknown failure -- no data received for $dist",
    );
    return PLUGIN_EAT_ALL
  }

  my $d_hash = 
    try { $Serializer->thaw($json) } 
    catch {
      broadcast( 'message',
        $hints->{Context}, $hints->{Channel},
        "thaw failure; err: $_",
      );
      undef
    } or return PLUGIN_EAT_ALL;

  unless ($d_hash && ref $d_hash eq 'HASH') {
    broadcast( 'message',
      $hints->{Context}, $hints->{Channel},
      "thaw failure for $dist; expected a HASH but got '$d_hash'"
    );
    return PLUGIN_EAT_ALL
  }

  my $resp;
  my $prefix = color bold => 'mCPAN';

  TYPE: {

    if ($type eq 'abstract') {
      my $abs  = $d_hash->{abstract} || 'No abstract available.';
      my $vers = $d_hash->{version};
      $resp = "$prefix: ($dist $vers) $abs ; $link";
      last TYPE
    }

    if ($type eq 'dist') {
      my $dl = $d_hash->{download_url} || 'No download link available.';
      $resp = "$prefix: ($dist) $dl";
      last TYPE
    }

    if ($type eq 'latest') {
      my $vers = $d_hash->{version};
      my $arc  = $d_hash->{archive};
      $resp = "$prefix: ($dist) Latest is $vers ($arc) ; $link";
      last TYPE
    }

    if ($type eq 'license') {
      my $name = $d_hash->{name};
      my $lic  = join ' ', @{ $d_hash->{license}||['undef'] };
      $resp = "$prefix: License terms for $name:  $lic";
      last TYPE
    }

    if ($type eq 'tests') {
      my %tests = %{
        keys %{$d_hash->{tests}||{}} ?
          $d_hash->{tests}
          : { pass => 0, fail => 0, na => 0, unknown => 0 }
      };

      my $vers = $d_hash->{version};

      $resp = sprintf("%s: (%s %s) %d PASS, %d FAIL, %d NA, %d UNKNOWN",
        $prefix, $dist, $vers,
        $tests{pass}, $tests{fail}, $tests{na}, $tests{unknown}
      );

      last TYPE
    }

    if ($type eq 'belongs') {
      my $release = $d_hash->{release};
      $resp = "$prefix: $dist belongs to release $release";
      last TYPE
    }

    if ($type eq 'changes') {
      my $release = $d_hash->{release};
      my $actuald = substr $release, 0, rindex $release, '-';
      my $link = "https://www.metacpan.org/changes/distribution/$actuald";
      $resp = "$prefix: Changes for $release: $link";
      last TYPE
    }

    logger->error("BUG; fell through in response handler");
  }

  broadcast( 'message',
    $hints->{Context}, $hints->{Channel},
    $resp
  ) if $resp;

  PLUGIN_EAT_ALL
}

1;
__END__

=pod

=head1 NAME

Bot::Cobalt::Plugin::Extras::CPAN - Query MetaCPAN API from IRC

=head1 SYNOPSIS

  ## Retrieve dist abstract:
  > !cpan Moo
  > !cpan abstract Bot::Cobalt

  ## Retrieve latest version:
  > !cpan latest POE

  ## Test summary:
  > !cpan tests POE::Component::IRC

  ## Download link:
  > !cpan dist App::bmkpasswd

  ## Find out what distribution a module belongs to:
  > !cpan belongs Lowu

  ## Get ChangeLog link:
  > !cpan changes Moo

  ## License info:
  > !cpan license Text::ZPL

  ## Query Module::CoreList:
  > !corelist Some::Dist

=head1 DESCRIPTION

A L<Bot::Cobalt> plugin providing an IRC interface to the
L<http://www.metacpan.org> API.

Retrieves CPAN distribution information; can also retrieve
L<Module::CoreList> data specifying when/if a distribution was included
in Perl core.

=head1 SEE ALSO

As of this writing, the authoritative reference for the MetaCPAN API
appears to be available at
L<https://github.com/CPAN-API/cpan-api/wiki/Beta-API-docs>

=head1 TODO

Some useful search features.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

L<http://www.cobaltirc.org>

=cut
