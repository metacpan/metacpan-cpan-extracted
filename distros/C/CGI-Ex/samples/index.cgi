#!/usr/bin/perl -w

=head1 NAME

index.cgi - Show a listing of available utilties in the samples directories.

=cut

use strict;
use base qw(CGI::Ex::App);
use FindBin qw($Bin);

__PACKAGE__->navigate;

sub main_file_print {
    return \ q{<html>
<head><title>CGI::Ex Samples</title></head>
<body>
<h1>CGI::Ex Samples</h1>
Looking at directory: [% base %]<br>
All of the samples in this directory should be ready to run.  To
enable this directory you should use something similar to the following in your apache conf file:
<pre>
ScriptAlias /samples/ /home/pauls/perl/CGI-Ex/samples/
&lt;Location /samples/>
    SetHandler perl-script
    PerlResponseHandler ModPerl::PerlRun
    Options +ExecCGI
&lt;/Location>
</pre>
For mod_perl 1 you would use something similar to:
<pre>
ScriptAlias /samples/ /home/pauls/perl/CGI-Ex/samples/
&lt;Location /samples/>
    SetHandler perl-script
    PerlHandler Apache::PerlRun
    Options +ExecCGI
&lt;/Location>
</pre>

<h2>Application examples</h2>
[% FOREACH file = app.keys.sort ~%]
<a href="[% script_dir ~ file %]">[% script_dir ~ file %]</a> - [% app.$file %]<br>
[% END -%]

<h2>Benchmark stuff</h2>
[% FOREACH file = bench.keys.sort ~%]
[% file %] - [% bench.$file %]<br>
[% END -%]

<h2>Other files</h2>
[% FOREACH file = therest.keys.sort ~%]
[% file %] - [% therest.$file %]<br>
[% END -%]

</body>
</html>
    };
}

sub main_hash_swap {
    my $self = shift;
    my $base = $self->base_dir_abs;
    my $hash = {};
    my %file;

    require File::Find;
    File::Find::find(sub {
        return if ! -f;
        return if $File::Find::name =~ / CVS | ~$ | ^\# /x;
        $File::Find::name =~ /^\Q$base\E(.+)/ || return;
        my $name = $1;
        my $desc = '';
        if (open FH, "<$_") {
            read FH, my $str, -s;
            close FH;
            if ($str =~ /^=head1 NAME\s+(.+)\s+^=cut\s+/m) {
                $desc = $1;
                $desc =~ s/^\w+(?:\.\w+)?\s+-\s+//;
            }
        }
        $file{$name} = $desc;
    }, $base);

    $hash->{'base'}    = $base;

    $hash->{'script_dir'} = $ENV{'SCRIPT_NAME'} || $0;
    $hash->{'script_dir'} =~ s|/[^/]+$||;

    $hash->{'app'}     = {map {$_ => $file{$_}} grep {/app/ && /\.cgi$/}    keys %file};

    $hash->{'bench'}   = {map {$_ => $file{$_}} grep {/bench/ && /\.pl$/}   keys %file};

    $hash->{'therest'} = {map {$_ => $file{$_}} grep {! exists $hash->{'bench'}->{$_}
                                                      && ! exists $hash->{'app'}->{$_}} keys %file};

    return $hash;
}

sub base_dir_abs {
    my $dir = $0;
    $dir =~ s|/[^/]+$||;
    return $dir;
}

