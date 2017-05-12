package Csistck;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.1003';

# We export function in the main namespace
use base 'Exporter';
our @EXPORT = qw(
    host
    role
    check
    option

    file
    noop
    pkg
    script
    template
);

# Imports for base
use Csistck::Config qw/option/;
use Csistck::Test::NOOP qw/noop/;
use Csistck::Test::File qw/file/;
use Csistck::Test::Pkg qw/pkg/;
use Csistck::Test::Script qw/script/;
use Csistck::Test::Template qw/template/;

use Csistck::Role;
use Csistck::Term;

use Sys::Hostname::Long qw//;
use Data::Dumper;
use Scalar::Util qw/blessed reftype/;
use List::Util qw/sum/;

# Package wide
my $Hosts = {};
my $Roles = {};


=head1 NAME

Csistck - Perl system consistency check framework

=head1 SYNOPSIS

    use Csistck;
    
    sub sig_hup_mysql { $ENV{'MAINT_HUP_MYSQL'} = 1; }

    for (qw/a b/) {
        host "$_.example.com" => role('mysql');
    }

    host 'c' => role('mysql');
    
    role 'mysql' => 
        pkg({
            dpkg => 'mysql-server',
            emerge => 'mysql'
        }),
        template(
            '/etc/mysql/my.cnf',
            src => 'mysql/my.cnf', 
            mysql => {
                bind => '127.0.0.1',
                keysize => '1G'
            },
            mode => '0644',
            uid => 100,
            gid => 100,
            on_restart => \&sig_hup_mysql
        ),
        script('services.sh');
            
    check;

The script can then be called directly, using command line arguments below

=head1 DESCRIPTION

Csistck is a small Perl framework for writing scripts to maintain system 
configuration and consistency. The focus of csistck is to stay lightweight,
simple, and flexible.

=head1 EXTENDING ROLES

Roles can be defined using the C<role> keyword syntax, however a more flexible
method is to extend a new object from L<Csistck::Role>:

    use Csistck;
    use base 'Csistck::Role';

    sub defaults {
        my $self = shift;
        $self->{config} = '/etc/example.conf';
    }

    sub tests {
        my $self = shift;
        $self->add(pkg({
            dpkg => 'test-server',
            pkg_info => 'net-test'
        }),
        template(
            $self->{config},
            src => 'files/example.conf',
            example => $self
        );

    }

    1;

See L<Csistck::Role> for information on extending roles


=head1 METHODS


=head2 host($host, $checks)

Add tests to host C<$host> test array. Tests are Csistck::Test blessed references, code
references, or arrays of either. To process host tests, use C<check()>.

=cut

sub host {
    my $hostname = shift;

    # Add domain if option is set?
    my $domain_name = Csistck::Config::option('domain_name');
    $hostname = join '.', $hostname, $domain_name
      if (defined $domain_name);

    while (my $require = shift) {
        push(@{$Hosts->{$hostname}}, $require);
    }

    return $Hosts->{$hostname};
}

=head2 role($role, $checks)

Define a weak role. Constructed similar to a host check, however roles are not
called directly, rather they are used to define groups of common tests that can
be used by multiple hosts.

See L<EXTENDING ROLES> above for an object-based style of defining roles, which
allows for passing role configuration.

=cut

sub role {
    my $role = shift;

    # If tests specified, add now
    while (my $require = shift) {
        push(@{$Roles->{$role}}, $require);
    }

    return sub { 
        # Run required role or die
        die ("What's this, \"${role}\"? That role is bupkis.")
          unless (defined $Roles->{$role});
        
        process($Roles->{$role});
    }
}

=head2 check($target)

Runs processing on C<$target>. If C<$target> is C<undef>, then look up the
system's full hostname. If C<$target> is a string, use that string for a
hostname lookup. If C<$target> is a C<Csistck::Test> reference, a coderef, or an
arrayref, then process that object directly. This is useful for writing scripts
where hostname is not important.

=cut

sub check {
    my $target = shift // Sys::Hostname::Long::hostname_long();

    # Process cli arguments for mode/etc, usage
    Csistck::Oper::set_mode_by_cli();
    return if (Csistck::Oper::usage());

    # Role names specified on the command line via --role have priority. If
    # target is a string, process as hostname reference. Otherwise, assume a
    # test object was passed
    if (scalar @{$Csistck::Oper::Roles} gt 0) {
        return process(
            map { role($_) } @{$Csistck::Oper::Roles}
        );
    }
    elsif (!defined(reftype($target))) {
        die ("What's this, \"${target}\"? That host is bupkis.")
          unless (defined $Hosts->{$target});
        return process($Hosts->{$target});
    }
    else {
        return process($target);
    }
}

# For recursive testing based on type
sub process {
    my $obj = shift;
    
    # Iterate through array and recursively call process, call code refs, 
    # and run tests

    given (ref $obj) {
        when ('ARRAY') {
            return map(process($_), @{$obj});
        }
        when ('CODE') {
            return &{$obj};
        }
        default {
            if (blessed($obj) and $obj->isa('Csistck::Test')) {
                # Check is mandatory, if auto repair is set, repair, otherwise prompt
                my $check = $obj->execute('check');
                return if ($check->passed);
                
                if (Csistck::Oper::repair()) {
                    my $repair = $obj->execute('repair');
                    if ($repair->passed and $obj->on_repair) {
                        &{$obj->on_repair};
                    }
                    return $repair;
                }
                else {
                    my $repair = Csistck::Term::prompt($obj);
                    if ($repair->passed and $obj->on_repair) {
                        &{$obj->on_repair};
                    }
                    return $repair;
                }
            }
            elsif (blessed($obj) and $obj->isa('Csistck::Role')) {
                return process($obj->get_tests);
            }
            else {
                die(sprintf("Unkown object reference: ref=<%s>", ref $obj));
            }
        }
    }
}

1;
__END__

=head1 EXPORTED METHODS

=head2 option($name, $value)

Set option to specified value.

=head3 Available Options

=over 3

=item *

pkg_type [string]

Set default package type

=item *

domain_name [string]

Set default domain name to append to hosts

=back

=head2 host($hostname, [@tests]);

Append test or array of tests to host definition. Most examples use the fat
comma delimiter syntax, however this is a subjective choice. 

    host 'hostname' => noop(1), noop(1);
    host 'hostname' => noop(0);

Returns a reference to the host object.

=head2 role($rolename, [@tests]);

Append test or array of tests to role definition.
    
    role 'test' => noop(0);
    host 'hostname' => role('test');

Returns a reference to the role object.


=head2 noop($return)

"No operation" test, used only for testing or placeholders.

    role 'test' => noop(1);

=head2 file($target, :$src, :$mode, :$uid, :$gid)

Copy file C<$src> to C<$target>, setting additional options with named arguments 
such as mode and uid.

    role 'test' => file(
        '/etc/lighttpd/lighttpd.conf',
        src => 'lighttpd/lighttpd.conf',
        mode => '0644'
    );

See L<Csistck::Test::File>

=head2 template($target, :$src, :$mode, :$uid, :$gid, [:$args])

Process file C<$src> as a Template Toolkit template, output to path C<$target>.
Optional named arguments can be used to alter the mode, uid, etc. All parameters
passed into the C<Csistck::Test::Template> object are available in the actual
template, so any additional named arguments are available in the template using
the argument's name -- these arguments should be hasrefs.

    role 'test' => template(
        '/etc/motd',
        src => 'sys/motd',
        foo => { bar => 1 },
        uid => 0,
        gid => 0,
        mode => '0640'
    );

See L<Csistck::Test::Template>

=head2 permission($glob, %args)

Change permissions on files matching file glob pattern

    role 'test' => permission("/etc/couchdb/*", {
        mode => '0640',
        uid => 130,
        gid => 130
    });

See L<Csistck::Test::Permission>

=head2 script($script, [@arguments])

Call script with specified arguments 

    role 'test' => script("apache2/mod-check", "rewrite");

See L<Csistck::Test::Script>

=head2 pkg($package, [$type])

Check for package using system package manager. The C<$package> argument may be
specified as a string, or as a hashref to specify package names for multiple
package managers. The package manager will be automatically detected if no
package manager is specified.

    option 'pkg_type' => 'dpkg';
    role 'test' => 
        pkg("lighttpd", 'dpkg'),
        pkg({
            dpkg => 'snmp-server',
            pkg_info => 'net-snmp'
        });

See L<Csistck::Test::Pkg> for more information

=head1 SCRIPT USAGE

Scripts based on Csistck will run in an interactive mode by default. 
The following command line options are recognized in a csistck based script

=over

=item *

B<--[no]repair>

Automate repair mode, do not run in interactive mode.

=item *

B<--[no]verbose>

Toggle verbose reporting of events

=item *

B<--[no]debug>

Toggle debug reporting of events

=item *

B<--[no]quiet>

Toggle event reporting of errors

=item *

B<--role=[ROLE]>

Instead of relying on a hostname lookup to execute the check, force check on
weak role ROLE instead. This option can be specified multiple times to check
multiple roles.

=back

=head1 AUTHOR

Anthony Johnson, C<< <aj@ohess.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011-2012 Anthony Johnson

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=cut
