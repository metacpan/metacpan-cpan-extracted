# Apache2::AuthCAS::Configuration
# Jason Hitt, March 2007
#
# Configuration module for Apache2::AuthCAS
package Apache2::AuthCAS::Configuration;

use strict;
use warnings FATAL => "all";

use Apache2::Const -compile => qw(OR_ALL);
  
use Apache2::CmdParms ();
use Apache2::Module ();
use Apache2::Directive ();
use Apache2::ServerUtil;

my @directives = (
    { cmd_data => 'Host',                    err_append => 'hostname',      },
    { cmd_data => 'Port',                    err_append => 'port',          },
    { cmd_data => 'LoginUri',                err_append => 'uri',           },
    { cmd_data => 'LogoutUri',               err_append => 'uri',           },
    { cmd_data => 'ProxyUri',                err_append => 'uri',           },
    { cmd_data => 'ProxyValidateUri',        err_append => 'uri',           }, 
    { cmd_data => 'ServiceValidateUri',      err_append => 'url',           },

    { cmd_data => 'LogLevel',                err_append => 'uri',           },
    { cmd_data => 'PretendBasicAuth',        err_append => '0/1',           },
    { cmd_data => 'Service',                 err_append => 'url',           },
    { cmd_data => 'ProxyService',            err_append => 'url',           },
    { cmd_data => 'ErrorUrl',                err_append => 'uri',           },
    { cmd_data => 'SessionCleanupThreshold', err_append => 'number',        },
    { cmd_data => 'SessionCookieName',       err_append => 'name',          },
    { cmd_data => 'SessionCookieDomain',     err_append => 'name',          },
    { cmd_data => 'SessionCookieSecure',     err_append => '0/1',           },
    { cmd_data => 'SessionTimeout',          err_append => 'name',          },
    { cmd_data => 'RemoveTicket',            err_append => '0/1',           },
    { cmd_data => 'NumProxyTickets',         err_append => 'number',        },

    { cmd_data => 'DbDriver',                err_append => 'driver',        },
    { cmd_data => 'DbDataSource',            err_append => 'string',        },
    { cmd_data => 'DbSessionTable',          err_append => 'session_table', },
    { cmd_data => 'DbUser',                  err_append => 'username',      },
    { cmd_data => 'DbPass',                  err_append => 'password',      },
);

foreach my $directive (@directives)
{
    $directive->{"name"}         = "CAS" . $directive->{"cmd_data"};
    $directive->{"func"}         = "CASConfig";
    $directive->{"req_override"} = Apache2::Const::OR_ALL;
    $directive->{"errmsg"}       = $directive->{"name"} . " " . $directive->{"err_append"};
    undef($directive->{"err_append"});
}
Apache2::Module::add(__PACKAGE__, \@directives);

sub DIR_MERGE
{
    my($base, $add) = @_;

    Apache2::ServerUtil->server->log->debug("DIR_MERGE");

    my %merged = ();
    foreach my $key (keys(%{$base}), keys(%{$add}))
    {
        next if (exists($merged{$key}));  # no need to do it twice

        my $b = $base->{$key} || 'undef';
        my $a = $add->{$key}  || 'undef';
        if ($b ne $a)
        {
            Apache2::ServerUtil->server->log->debug("merge: $key => $b");
            Apache2::ServerUtil->server->log->debug("       $key => $a");
        }
        $merged{$key} = $base->{$key} if exists($base->{$key});
        $merged{$key} = $add->{$key}  if exists($add->{$key});
    }

    return bless(\%merged, ref($base));
}

sub CASConfig($$$)
{
    my ($self, $parms, $data) = @_;

    my $which = $parms->info();

    Apache2::ServerUtil->server->log->debug("    Setting $which to $data");
    if ($which eq "LogLevel")
    {
        # Validate the argument is a valid log level
        unless ($data >= 0 and $data <= 4)
        {
            my $directive = $parms->directive;
            die(sprintf("ERROR: CASConfig at %s:%d expects "
                . " a number 0-4: ('$data' is not correct)\n",
                $directive->filename, $directive->line_num
            ));
        }

        $self->{LogLevel} = $data;
    }
    elsif ($which eq "Port")
    {
        # Validate the argument is a valid port number
        unless ($data > 0 and $data <= 65535)
        {
            my $directive = $parms->directive;
            die(sprintf("ERROR: CASConfig at %s:%d expects "
                . " a number 1-65535: ('$data' is not correct)\n",
                $directive->filename, $directive->line_num
            ));
        }

        $self->{Port} = $data;
    }
    elsif ($which eq "PretendBasicAuth" or $which eq "RemoveTicket")
    {
        $self->{$which} = ($data =~ /(1|true)/i) ? 1 : 0;
    }
    else
    {
        $self->{$which} = $data;
    }
}

1;
