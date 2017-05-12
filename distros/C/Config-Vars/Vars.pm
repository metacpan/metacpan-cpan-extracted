=head1 NAME

Config::Vars - A module for keeping configuration variables in a central perl file.

=head1 VERSION

This documentation describes version 0.01 of Config::Vars.pm, May 23, 2003.

=cut

use strict;
package Config::Vars;
use vars qw/$VERSION @CARP_NOT/;
$VERSION = 0.01;

use Carp;
use Filter::Simple;
@CARP_NOT = qw(Filter::Simple);

# Can we use Readonly?
use vars '$RO_ok';
my $nowarn;       # if true, don't kvetch about Readonly not being available
my $export;       # Exporter array name
eval { require 'Readonly.pm' };
$RO_ok = 1 unless $@;

# These get set by import() at the begining of each module; reset by xform.
my $usevars;
my $isa;


sub import
{
    my $pkg = shift;
    my @errs;

    # Module-by-module init
    $nowarn = 0;
    $export = 'EXPORT_OK';

    foreach my $opt (@_)
    {
        if ($opt eq 'nowarn')
        {
            $nowarn = 1;
        }
        elsif ($opt eq 'exportall')
        {
            $export = 'EXPORT';
        }
        else
        {
            push @errs, $opt;
        }
    }
    my $s = @errs > 1? 's' : '';
    croak "Unknown Config::Vars option$s (@errs)" if @errs;

    $usevars = "\@$export \@ISA ";
    $isa     = "\n" . q(push @ISA, 'Exporter' unless grep $_ eq 'Exporter', @ISA;);
}


# Filter the code
# Change
#        var $foo = 'bar';
# into
#        use vars qw($foo);
#        push @EXPORT_OK, qw($foo);       # or, push @EXPORT, qw($foo);
#        $foo = 'bar';
FILTER_ONLY
    code => sub {
#        print STDERR "BEFORE: [$_]\n";
        s/^ \s*                # optional leading whitespace
            (var|ro)           # 'var' or 'ro' keyword
            \s+                # mandatory whitespace
            ([^=;\s]+)         # a variable name
            \s*                # optional whitespace
            (\S)               # = or semicolon
         /xform($1,$2,$3)/gemx;
#        print STDERR "AFTER: [$_]\n";
    };


sub xform
{
    my ($cmd, $var, $eqs) = @_;
    croak qq{Can't process "$cmd $var $eqs" line} if $cmd ne 'var' && $cmd ne 'ro';
    unless ($var =~ /^[\$\@\%][_[:alpha:]]\w+/)
    {
        croak qq{May not declare individual hash or array elements with $cmd}
            if $var =~ /\[[^\]]\]/ || $var =~ /\{[^\}]+\}/;
        croak qq{May not declare globs with $cmd ("$var")} if substr($var,0,1) eq '*';
        croak qq{Invalid variable name "$var"};
    }
    croak qq{Can't process "$cmd $var" line} if $eqs ne '='   && $eqs ne ';';

    my $res = <<USE_AND_EXPORT;
use vars qw($usevars$var);$isa
push \@$export, qw($var);
USE_AND_EXPORT

    if ($cmd eq 'ro'  &&  $RO_ok)
    {
        $res .= "Readonly::Readonly \\$var";
        $res .= ' => ' if $eqs eq '=';
    }
    else
    {
        carp "Readonly not available, making $var read/write" if $cmd eq 'ro'  &&  !$nowarn;
        $res .= $var;
        $res .= ' = '  if $eqs eq '=';
    }
    $res .= $eqs  if $eqs eq ';';
    $usevars = $isa = '';
    return $res;
}


1;    # Modules must return true, for silly historical reasons.
__END__

=head1 SYNOPSIS

 package My_Config_File;
 use Config::Vars;

 # Declare and initialize some variables in your config file.
 var $foo  = 'some value';
 var $arr  = qw(some values);
 var %hash = (some => 'values');

 # Declare an initialize some readonly variables.
 ro $foo2  = 'some value';
 ro $arr2  = qw(some values);
 ro %hash2 = (some => 'values');

=head1 DESCRIPTION

Most sizeable projects require a number of configuration variables to
be stored somewhere.  Sometimes a config file is the best solution for
this, but often a plain Perl module is used for this.  The nice thing
about using a Perl module is that you can do computations in the file,
for example, initializing variables from previously-defined ones.

The problem is that you have to do a bunch of repetitive accounting
work to ensure the variables will be accessible from your main program
and other modules.  You should set up the module as an Exporter so
that all the various components of your system will have access to the
config variables in their own namespaces.  You then need to put all of
the config variable names into @EXPORT_OK.  If you want your module to
be strict-safe, you need to declare them all with C<our> or C<use
vars>.  Finally, you have to initialize the variable.  It goes
something like this:

 @EXPORT_OK = qw($president);
 use vars qw($president);
 $president = 'Grover Cleveland';

Writing each variable name three times is a tedious waste of time.
This module takes care of the repetitive coding tasks that you need to
do in order to make your configuration module work.

Config::Vars also takes care of importing the Exporter module and
setting up @EXPORT_OK and @ISA.

=head1 USE

 use Config::Vars;
 use Config::Vars qw(nowarn exportall);

By default, Config::Vars puts the variables you declare into
@EXPORT_OK and C<warn>s when you use "ro" to declare variables when
the Readonly module is not available.

If you use the 'nowarn' option, Config::Vars will not issue a warning
when you use "ro" when Readonly is not installed.  This can be useful
if you want to enforce read-only-ness on systems where Readonly is
installed, but still want your program to work without complaint on
systems where it's not installed.

If you use the 'exportall' option, Config::Vars puts all of your
declared variables into @EXPORT instead of @EXPORT_OK.  This is not
recommended in general, because it can lead to hard-to-find bugs
involving variable name collisions.  But it can sometimes be
convenient for small config files if you're aware of the issues.

See the Exporter module documentation for information on @EXPORT_OK
and @EXPORT.

=head1 DIRECTIVES

=over 4

=item var

 var $variable_name = $some_value;
 var @variable_name = @some_values;
 var %variable_name = %some_values;

This declares a variable.  The variable is initialized and its name is
appended to @EXPORT_OK.

=item ro

 ro $variable_name = $some_value;
 ro @variable_name = @some_values;
 ro %variable_name = %some_values;

This declares a readonly variable, if you have the Readonly module
installed.  If you don't, a warning will be printed to STDERR and the
module will continue as if you had used C<var>.

If you don't want the warning message to be displayed, specify "nowarn"
on the "use Config::Vars" line; see USE above.

=back

=head1 EXAMPLE

 # ==== CONFIG FILE MyConfig.pm ====
 use strict;
 package MyConfig;
 use Config::Vars;

 ro $db_user    = 'my_db_app';      # database application username
 ro $db_pw      = $database_user;   # password (often the same as username)
 ro $db_connect = 'dbi:mysql';      # database connect string
 var $dbh;                          # global database handle
 # ==== END CONFIG FILE ====

 # ==== SOME LIBRARY Lib.pm ====
 use strict;
 package Lib;
 use MyConfig qw($db_user $db_pw $db_connect $dbh);

 sub connect
 {
     $dbh = DBI->connect($db_connect, $db_user, $db_pw);
     die "Can't connect" unless $dbh;
 }
 # ==== END LIBRARY Lib.pm ====

 # ==== MAIN PROGRAM ====
 use strict;
 use MyConfig qw($dbh);    # Configuration variables for this app
 use Lib;         # Utility library for this app

 Lib::connect;    # Call utility function

 # Now $dbh is available.  Lib.pm and main share the same $dbh
 my $sth = $dbh->prepare(...)
 # ==== END MAIN PROGRAM ====


=head1 BUGS AND LIMITATIONS

=over 1

=item *

All errors are reported as being from the "use Config::Vars" line of
the calling module, instead of the line where the error actually
occurred.

=item *

'var' and 'ro' are only recognized if they are the first non-whitespace
characters on the line.  Thus the following won't work:

 var $foo=7; var $bar=8;

=item *

The first non-whitespace character after the variable name on a 'var'
or 'ro' line must be a semicolon or an equals sign.  So the following
would not be accepted:

 var %is_bird        # This comment messes things up.
     = ( vulture => 1, tiger => 0 );

=back

=head1 EXPORTS

The following symbols appear to be exported, but they're actually sort
of magical (because they're implemented via source filter).

 var
 ro

=head1 REQUIREMENTS

 Carp
 Filter::Simple
 Readonly      (if you want the 'ro' directive to work)

=head1 SEE ALSO

The Exporter module, especially the bits about @EXPORT_OK and @EXPORT.

The Camel book, esp. the bits about @ISA and C<use vars>.

The Reaodnly module.

=head1 AUTHOR / COPYRIGHT

Eric J. Roode, roode@cpan.org

Copyright (c) 2003 by Eric J. Roode. All Rights Reserved.  This module
is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

If you have suggestions for improvement, please drop me a line.  If
you make improvements to this software, I ask that you please send me
a copy of your changes. Thanks.
