package AutoRole;

=head1 NAME

AutoRole - Compiletime OR runtime mixin of traits/roles/mixins/your-word-here.

$Id: AutoRole.pm,v 1.8 2011-10-06 16:55:06 paul Exp $

=cut

use strict;
use warnings;

$AutoRole::VERSION = '0.04';

sub import {
    my ($class, @args) = @_;
    my ($pkg, $file, $line) = caller;
    my ($module, $how, %list);

    while (@args) {
        my $item = shift(@args) || next;
        if    ($item eq 'class') { $module = shift(@args) || die "Missing class name at $file line $line\n"; next }
        elsif ($item eq 'how')   { $how    = shift(@args) || die "Missing how type at $file line $line\n";   next }
        elsif ($item =~ m{methods?}x) { $args[0] = [$args[0]] if ! ref $args[0]; next }

        if (ref $item) {
            if (ref $item eq 'ARRAY') { @list{ @$item } = @$item; next }
            if (ref $item eq 'Regexp') { $how = 'compile'; push @{ $list{'*'} }, $item; next }
            while (my ($k, $v) = each %$item) {
                next if ! $v;
                if ($k eq '*') { push @{ $list{'*'} }, ref($v) eq 'ARRAY' ? @$v : ref($v) ? $v : qr{.}x; next }
                $list{$k} = (ref($v) || $v =~ /^[^\W\d]\w+$/x) ? $v : $k;
            }
            next;
        }
        if ($item =~ /^(?:compile|autoload|autorequire)$/x) { $how = $item }
        elsif ($item eq '*') { push @{ $list{'*'} }, qr{.}x }
        elsif (! $module) { $module = $item }
        else { $list{$item} = $item }
    }

    die "Missing class name at $file line $line\n" if ! $module;
    (my $module_file = "$module.pm") =~ s{::}{/}xg;
    if (! scalar keys %list) {
        if (!$how || $how eq 'compile') { $list{'*'} = [qr{.}x] }
        else { die "Missing list of methods to load at $file line $line\n" }
    }
    $how ||= 'autorequire';
    no strict 'refs';

    my $star = delete $list{'*'};
    if ($star) {
        require $module_file;
        for my $k (grep {defined &{"${module}::$_"}} keys %{"${module}::"}) {
            $list{$k} ||= $k for grep {$k =~ $_} @$star;
        }
        die "No methods found matching @$star for loading at $file line $line\n"
            if ! scalar keys %list;
    }

    $how = 'compile' if $INC{$module_file};
    if ($how eq 'compile') {
        require $module_file;
    } elsif ($how eq 'autoload') {
        no warnings;
        my $ref  = ${"${pkg}::AUTOROLE"} ||= {};
        my $code = \&{"${pkg}::AUTOLOAD"};
        *{"${pkg}::AUTOLOAD"} = sub {
            my $dest = ($AutoRole::AUTOLOAD || ${"${pkg}::AUTOLOAD"} || q{}) =~ /::(.+)$/x ? $1 : return;
            if (exists $ref->{$dest}) {
                require $module_file;
                *{"${pkg}::$dest"} = $module->can($dest) || die "No such method as ${module}::$dest - $file line $line\n";
                goto &{"${pkg}::$dest"}; # avoid inserting ourselves into the stack
            }
            if ($code ||= $pkg->SUPER::can('AUTOLOAD')) {
                local ${"${pkg}::AUTOLOAD"} = "${pkg}::$dest";
                return $code->(@_);
            }
        };
    } elsif ($how ne 'autorequire') {
        die "How type \"$how\" is invalid at $file line $line\n";
    }

    foreach my $src (keys %list) {
        foreach my $dest (ref($list{$src}) ? @{ $list{$src} } : $list{$src}) {
            if (defined &{"${pkg}::$dest"}) {
                die "Method name conflict - ${pkg}::$dest already exists - $file line $line\n";
            } elsif (defined(${"${pkg}::AUTOROLE"}) && exists(${"${pkg}::AUTOROLE"}->{$dest})) {
                die "Method name conflict -- ${pkg}::$dest is already set to autoload - $file line $line\n";
            }

            if ($how eq 'compile') {
                *{"${pkg}::$dest"} = *{"${module}::$src"}{'CODE'};
            } elsif ($how eq 'autoload') {
                ${"${pkg}::AUTOROLE"}->{$dest} = $src;
            } else {
                *{"${pkg}::$dest"} = sub {
                    require $module_file;
                    no warnings;
                    *{"${pkg}::$dest"} = $module->can($src) || die "No such method as ${module}::$src - $file line $line\n";
                    goto &{"${pkg}::$dest"}; # avoid inserting ourselves into the stack
                };
            }
        }
    }
    return ($star && wantarray) ? [sort keys %list] : 1;
}

1;

__END__

=head1 SYNOPSIS

  use AutoRole Bam => [qw(bar baz bim)];

  use AutoRole
    class   => 'Bam',
    how     => 'autorequire',
    methods => [qw(bar baz bim)];

  use AutoRole
    class   => 'Bam',
    how     => 'compile',
    methods => {
       bar => 1,
       baz => 1,
       bim => 'bim_by_some_other_name',
    };

  use AutoRole
    class   => 'Bam',
    how     => $ENV{'MOD_PERL'} && 'compile', # will default to autorequire if not mod_perl
    method  => 'flimflam',

  use AutoRole
    class   => 'Bam',
    how     => 'autoload', # better if you are using many many mixin methods
    methods => [qw(bar baz bim biz boon bong brim)];

  use AutoRole Bam => [qw(bar baz bim)];
  use AutoRole Bam => autorequire => [qw(bar baz bim)]; # same thing
  use AutoRole Bam => compile     => [qw(bar baz bim)];

  use AutoRole Bam => methods => '*';      # load ALL methods from Bam - at compile time
  use AutoRole Bam => '*';                 # same thing
  use AutoRole 'Bam';                      # same thing
  use AutoRole Bam => {'*' => qr{^bam_}};  # load All methods from Bam that begin with bam_
  use AutoRole Bam => qr{^bam_};           # same thing

  use AutoRole Bam => qr{^(?!bam_)};       # load ALL methods not beginning with bam_

=head1 DESCRIPTION

AutoRole is similar to many of the CPAN variants that handle things
refered to as Traits, Roles, and Mixins.  All of these are fairly
similar to each other (in Perl land) though there are subtle nuances.
If you use the type C<how> of compile - there is little difference in
using AutoRole vs. the CPAN counterparts.

If you use autorequire or autoload however, you save loading the
modules until it is necessary to do so.  This allows for the creation
of "heavy" interfaces with very light frontends.  AutoRole allows for
only loading extra modules if that role's interface is used.

One more win with roles/mixins/traits is that you can keep your
inheritance tree sane (rather than inheriting from a role class).

=head1 PARAMETERS

In many cases the class, how, and method keywords are not needed and
the intent can be determined based on the types of parameters.
However, you can always pass the parameter names to be specific.

=over 4

=item C<class>

This represents the class you would like to load the roles from.

=item C<how>

Can be one of compile, autorequire, or autoload.  Default is
autorequire if methods are passed, default is compile if no methods
are passed or if '*' or qr{} are used for methods.

Option C<compile> will load the module and mix the specified
subs/methods in as needed at compile time.

Option C<autorequire> does not load the module at compile time,
instead it loads a stub subroutine that will require the module,
re-install the real subroutine in place of the stub, and then goto
that subroutine (to keep the call stack like it should be).

Option C<autoload> tries to do as little work as possible by only
installing an AUTOLOAD subroutine that will load the role methods when
called.  This is a good option over autorequire if you have a large
number of role methods (it gives more of a runtime hit rather than a
compiletime hit).

=item C<methods> or C<method>

Takes an arrayref or hashref of names  or a single method name to load.  If a hashref
is passed, the value may be a different name to alias it to, or an arrayref of names
to alias to.

    method => 'foo'

    methods => 'foo'

    methods => ['foo'],

    methods => {foo => 1},

    methods => {foo => 'foo'}

    methods => {foo => 'bar'}           # installs a method called bar rather than foo
    methods => {foo => ['bar', 'baz']}  # installs both bar and baz as rather than foo

You can use the special method name of C<*> to load all of the methods from the sub.
The downside to this is it will automatically change to compile time behavior (because
it needs to lookup the list of available methods).

    method => '*'

    method => {'*' => 1},

If the methods are specified with a hashref, the value of a C<*> entry
may be a regex that will be used to match method names.  Note however that this
retrieval is only one class deep - so if your role inherits from a base role you
will need to load it separately.

    method => {'*' => qr{^debug}} # loads all methods beginning with debug

    methods => {foo => 1,
                '*' => qr{^bar},  # loads foo and any other method beginning with bar
               }

If you use C<*> and other aliases at the same time, the other aliases win.

Since it is a common thing to do - you may also pass simply a qr{} and it will
work like {'*' => qr{}}.

    methods => qr{^debug}     # load all methods beginning with debug

    methods => qr{^(?!debug)} # load all methods not beginning with debug

If the how option is C<compile> and no method or methods are passed, it will default to
'*'.  However if no methods are passed on autorequire or autoload, it will die.

=back

=head1 DIAGNOTICS

=over 4

=item C<Missing class name>

Occurs when the C<class> paramter name is used but no class name follows.

=item C<Missing how type>

Occurs when the C<how> type is used but no type follows.

=item C<How type $how is invalid>

Type can only be compile or autorequire.

=item C<Method name conflict - ${pkg}::$dest already exists>

Occurs if you try and use a method name from a role that is already defined
as a method in your class.  You can work around this by using the alias feature
of the C<method> parameter.

=item C<Missing list of methods to load>

Occurs if you fail to pass a list of methods during autorequire or autoload.
Note that if you don't pass a list under how type C<compile> it will default
to '*'.

=back

=head1 AUTHOR

Paul Seamons

=head1 LICENSE

This module may be distributed under the same terms as Perl itself.

=cut
