package Dancer::Plugin::ExtDirect;
{
  $Dancer::Plugin::ExtDirect::VERSION = '1.03';
}
# ABSTRACT: ExtDirect plugin for Dancer
use strict;
use warnings;

use Dancer ':syntax';
use Dancer::Plugin;
use JSON ();

# The best Ext Direct docs out there are provided by the Django implementation:
# https://github.com/gsancho/extdirect.django

register extdirect => sub ($) {
    my $init = shift;
    
    # validate config hashref
    $init->{api}
        or die "'api' route handler required\n";
    
    ref $init->{actions} eq 'HASH'
        or die "'actions' parameter required\n";
    
    get $init->{api} => sub {
        my $actions = {};
        foreach my $class (keys %{$init->{actions}}) {
            $actions->{$class} = [];
            foreach my $method (keys %{$init->{actions}{$class}}) {
                push @{$actions->{$class}}, {
                    name  => $method,
                    len   => $init->{actions}{$class}{$method}{len},
                    $init->{actions}{$class}{$method}{formHandler} ? (formHandler => JSON::true) : (),
                };
            }
        }
        
        content_type 'text/javascript';
        sprintf "Ext.Direct.addProvider(%s);\n",
            to_json {
                url       => request->path . '/router',
                type      => 'remoting',
                actions   => $actions,
                $init->{namespace} ? (namespace => $init->{namespace}) : (),
                $init->{provider_config} ? %{$init->{provider_config}} : (),
            };
    };
    
    post $init->{api} . '/router' => sub {
        my @splat = splat;
        
        my $requests = [];
        if (params->{extAction}) {
            push @$requests, {
                action  => params->{extAction},
                method  => params->{extMethod},
                tid     => params->{extTID},
                type    => params->{extType},
                upload  => params->{extUpload},
                data    => [ { map +($_ => params->{$_}), grep !/^ext(Action|Method|TID|Type|Upload)$/, keys %{&params} } ],
            };
        } else {
            $requests = from_json(request->body)
                or return status 400;
            
            # wrap the request if we didn't get an array
            $requests = [ $requests ] if ref $requests ne 'ARRAY';
        }
        
        # check whether we can accept the incoming requests
        foreach my $request (@$requests) {
            $init->{actions}{$request->{action}}
                && $init->{actions}{$request->{action}}{$request->{method}}
                && $init->{actions}{$request->{action}}{$request->{method}}{len} == scalar(@{$request->{data} || []})
                    or return status 400;
        }
        
        # process requests
        my @results = ();
        foreach my $request (@$requests) {
            my $handler = $init->{actions}{$request->{action}}{$request->{method}}{handler};
            my $rv = eval { $handler->(@splat, @{$request->{data}}) };
            if ($@) {
                if ($init->{debug}) {
                    push @results, {
                        type    => 'exception',
                        message => $@,
                    };
                } else {
                    return status 500;
                }
                next;
            }
            push @results, {
                type    => 'rpc',
                tid     => $request->{tid},
                action  => $request->{action},
                method  => $request->{method},
                result  => $rv,
            };
        }
        
        # return results
        content_type 'application/json';
        to_json \@results;
    };
};

register_plugin;

1;


__END__
=pod

=head1 NAME

Dancer::Plugin::ExtDirect - ExtDirect plugin for Dancer

=head1 VERSION

version 1.03

=head1 SYNOPSIS

    use Dancer::Plugin::ExtDirect;
    
    # basic example:
    extdirect {
        api         => '/api',
        actions     => {
            'Calculator' => {
                sum => { len => 2, handler => \&sum },
            },
        },
    };
    sub sum {
        my ($a, $b) = @_;
        return $a + $b;
    }
    
    # a bit more complex example:
    any qr{ /projects/.* }x => sub {
        # chain route handlers to check permissions
        # for ExtDirect calls too
        pass;
    };
    extdirect {
        api         => '/projects/*/api',  # the wildcard values are passed to handlers
        namespace   => 'MyApp',
        actions     => {
            'Project' => {
                addUser => { len => 1, handler => \&addUser },
            },
        },
    };
    sub addUser {
        my ($project_id, $user) = @_;
        ...
    }
    
    # in HTML:
    <script type="text/javascript" src="/api"></script>
    <script type="text/javascript" src="/projects/2/api"></script>
    <script type="text/javascript">
        alert("3 + 2 = " + Calculator.sum(3,2));
        MyApp.Project.addUser({ name => 'Harry' });
    </script>

=head1 METHODS

=head2 extdirect

This method sets up a Dancer route handler to expose some functions to
your JavaScript client-side application. It accepts a hashref containing 
the following options.

=over 4

=item B<api>

This accepts a route handler URI path, such as C</api>. You can also use Dancer 
wildcards such as C</projects/*/api>, so that the values caught are passed to 
your method handlers.

=item B<namespace>

This option is injected to the addProvider method call.

=item B<provider_config>

This accepts a hashref with additional config options that will be injected to
the addProvider method call.

=item B<actions>

This accepts a hashref whose keys are ExtDirect class names and their values are
hashrefs with the method definitions (see the synopsis above for an example).
Each method is defined by a hashref having the following keys:

=over 8

=item I<len>

The number of arguments that the exported function accepts.

=item I<handler>

A coderef (or reference to a subroutine) that will handle the request. Note
that this module doesn't force you to map the exposed ExtDirect class to 
any particular Perl class layout.
The handler subroutine will be called with the arguments coming from the 
client-side. If you used any wildcards in the C<api> path, the values caught
(with Dancer's C<splat> method) will be prepended to the arguments.

=item I<formHandler>

Optional. Mark this as true to handle ExtJs form (see ExtJs docs about the
formHandler API).

=back

=item B<namespace>

Optional. The JavaScript namespace under which the API will be exported.

=item B<debug>

Optional. Mark this as true to send ExtDirect exceptions when the handler 
dies. Default is false, meaning that Dancer will just throw a 500 Internal
Server Error with no details exposed.

=back

=head1 AUTHOR

Alessandro Ranellucci <aar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Alessandro Ranellucci.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

