package Config::FreeForm;
use strict;
use Carp;
use vars qw/$VERSION $CONF_DIR %_Sets %_Stat $DEBUG/;
$VERSION = '0.01';
use Data::Dumper;

sub import {
    my $class = shift;
    croak "import: Not an even number of arguments" if @_%2;
    my %p = @_;
    if ($p{dir}) {
        $CONF_DIR = $p{dir};
    }
    else {
        ($CONF_DIR = __FILE__) =~ s/\.pm$//;
    }
    $DEBUG = $p{debug};
    for my $set ( @{ $p{sets} } ) {
        $_Sets{$set} = "$CONF_DIR/$set.conf";
        reload($set);
    }
}

sub reload_changed {
    no strict 'refs';
    for my $set (keys %_Sets) {
        my $mtime = (stat $_Sets{$set})[9];
        warn(__PACKAGE__ . ": Can't locate $_Sets{$set}\n"), next
            unless defined $mtime && $mtime;

        if (!$_Stat{$set} || $mtime > $_Stat{$set}) {
            warn sprintf "%s: process %d reloading %s (%d < %d)\n",
                __PACKAGE__, $$, $set, $_Stat{$set} || 0, $mtime
                if $DEBUG;
            reload($set);
        }
        $_Stat{$set} = $mtime;
    }
}

sub reload {
    my $set = shift;
    croak "reload: $set not found" unless exists $_Sets{$set};
    my $conf = do $_Sets{$set};
    no strict 'refs';
    for my $key (keys %$conf) {
        *{ __PACKAGE__ . '::' . $key } = \$conf->{$key};
    }
}

sub handler {
    my $r = shift;
    $DEBUG = ($r->dir_config("ConfigDebug") || '') eq 'on';
    reload_changed();
    return 1;
}

sub rewrite {
    my $set = shift;
    my $file = shift || $_Sets{$set};
    my $hash;
    {
        no strict 'refs';
        $hash = { $set => ${ __PACKAGE__ . "::${set}" } };
    }
    local *FH;
    open FH, ">" . $file
        or croak "Can't open $file: $!";
    local $Data::Dumper::Indent = 1;
    local $Data::Dumper::Purity = 1;
    print FH Dumper($hash);
    close FH or croak "Can't close $file: $!";
}

=head1 NAME

Config::FreeForm - Provide in-memory configuration data

=head1 SYNOPSIS

    use Config::FreeForm %options;

=head1 DESCRIPTION

I<Config::FreeForm> provides in-memory configuration data
in a free-form manner. Many existing configuration modules
attempt to provide some structure to your configuration
data; in doing so, they force you to use their own
configuration paradigm (association of keywords with values,
etc.). Often this isn't what you need in a complex
application--you need complete control over your configuration
data, and you need the ability to structure it however you
like. This is what I<Config::FreeForm> gives you.

In I<Config::FreeForm> configuration data is stored as a
Perl data structure. The logic behind this is that you know
Perl--you shouldn't need to learn another little language
to set up your configuration data, however simple that
language may be. Of course, this works best if programmers
or tools do the updating of your configuration files; it
does make it more difficult for other possible users to edit
the files. If this is a problem for you, try some of the
other configuration modules listed in I<MISCELLANEOUS>.

Still here? Good. You might then ask what I<Config::FreeForm>
gives you that rolling your own light module using I<Data::Dumper>
and I<do> would not. It's a good question, considering in
particular that I<Config::FreeForm> uses I<Data::Dumper>
and I<do> to write and read your data, respectively.
I<Config::FreeForm> adds some very nice features, though:

=over 4

=item * Configuration File Management

So as not to clutter one file with configuration for all
purposes, you can separate your configuration data into
multiple files, and specify which files to load when you
load in the module:

    use Config::FreeForm sets => [ ... ];

I<Config::FreeForm> manages the various configuration files
that you've told it to load, and lets you update your
data in memory, then write it back to its original location
on disk, using the I<rewrite> function (below, in
I<UPDATING CONFIGURATION>).

=item * Automated Reloading

In a I<mod_perl> context, your configuration data will be
loaded once, at webserver startup; subsequent access to the
configuration data will come from memory. If you update
your configuration on disk, then, you'll want those
changes to be reflected in the in-memory versions of the
configuration. I<Config::FreeForm> will handle this
automatically for you if you install it as a I<PerlInitHandler>
on your I<mod_perl>-enabled server. For more details, see
I<AUTOMATED RELOADING>, below.

=back

=head1 HOW TO USE IT

To create a configuration file, add its configuration to a
file like I<Foo.conf>:

    $conf = {
        Foo => { Bar => 1 }
    }

Once you've written your I<Foo.conf> configuration file,
load that file explicitly (without the I<.conf>):

    use Config::FreeForm sets => [ 'Foo' ];

When the module is loaded, it will attempt to find a
configuration file for the set I<Foo>; it will load the
data in this file using I<do>; then it will loop over
the top-level variables in the tree structure and alias
variables into the I<Config::FreeForm> namespace to the
values in the structure.

For example, if you have the above I<Foo.conf>, the
variable I<$Config::FreeForm::Foo> will be equal to the
following structure:

    {   Bar => 1   }

So you could access the value of the I<Bar> attribute
by treating the aliased variable as a hash
reference:

    my $value = $Config::FreeForm::Foo->{Bar};

In addition to specifying which configuration files to
load, you can use the I<%options> in the import list to
set the directory holding the configuration files. By
default I<Config::FreeForm> looks in the directory
I<FreeForm> within the directory from which it was loaded
for the files. For example, if the module were loaded
from F</foo/bar/Config/FreeForm.pm>, the I<Foo.conf>
configuration file would be default be looked up in
F</foo/bar/Config/FreeForm/Foo.conf>.

By using the I<dir> import list parameter, though, you
can override this default behavior:

    use Config::FreeForm dir => '/foo', sets => [ 'Foo' ];

This would look up F<Foo.conf> in the directory I</foo>.

=head1 UPDATING CONFIGURATION

If you wish to update the configuration files
programatically (as opposed to editing them by
hand), you can use the I<rewrite> function.

This is a two-step process. First, you'll need to update
the in-memory configuration--just make a change to one
of the variables. For example:

    $Config::FreeForm::Foo->{Bar} = 2;

This updates the configuration in memory; now you need
to write the configuration to the disk. You can do
that using I<rewrite>, which takes the name of a
configuration "set" (which corresponds to the name of
the configuration file). In this case, that set would
be I<Foo>:

    Config::FreeForm::rewrite('Foo');

And you're done. The configuration is now updated on
disk.

If you'd like to write the configuration data to a
file different than that from which it was read, you
can pass a filepath as a second argument. For example:

    Config::FreeForm::rewrite('Foo', './myfoo.conf');

This will write out the I<Foo> configuration data to
F<./myfoo.conf>.

Keep in mind that, if you're rewriting your configuration
in a webserver context, you'll want your on-disk changes
to propagate to the other webserver children (the children
in which you didn't already change the in-memory
configuration). Read on--this can be made to happen
automatically.

=head1 AUTOMATED RELOADING

When used in a webserver context, the configuration files
are parsed once at webserver startup, then stored in
memory. If changes occur in the configuration files, under
normal circumstances the configuration stored in memory
would not be reloaded. However, I<Config::FreeForm> has a
built-in capability to automatically reload configuration
files that have changed on disk. This allows you to make
a change to a config file, then let the webserver
automatically pick up the new changes.

This is particularly important when using the I<rewrite>
function; if you alter the in-memory configuration, then
write the file to disk, you want the other webserver
children to pick up the changes, in addition to the child
where you actually made the in-memory changes. Using the
automated reloading, these changes will be automatically
picked up by all of the webserver children.

To use this capability, just install I<Config::FreeForm> as
a I<PerlInitHandler> in the webserver. Add this to the
configuration:

    PerlInitHandler Config::FreeForm

You can either stick this into a I<Location> block or make
it global for your entire server. The latter may be easier
in terms of maintenance, but the former may give you more
flexibility.

By default, I<Config::FreeForm> will go about its business
quietly. If you'd like it to write a message to the error
log each time it reloads a configuration file, you can
add a configuration directive to do so:

    PerlSetVar ConfigDebug on

Now, each time I<Config::FreeForm> reloads a configuration
file, it will write a message to the log file telling
you the process ID, the configuration set, and the
modified-time comparison that caused the reload.

=head1 MISCELLANEOUS

If the so-called freeform nature of I<Config::FreeForm>
doesn't appeal to you, and you'd like a more structured
approach to your configuration files, check out
I<App-Config>, I<Boulder>, or I<XML::Simple>.

=head1 AUTHOR

Benjamin Trott, ben@rhumba.pair.com

=cut

1;
