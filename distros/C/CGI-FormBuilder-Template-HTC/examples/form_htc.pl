#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use blib;
use CGI::FormBuilder;


use Fcntl qw(:seek);

my ($template, $perlcode);
{
    local $/;
    $template = <DATA>;
    seek DATA, 0, SEEK_SET;
    $perlcode = <DATA>;
}

my $form = CGI::FormBuilder->new(
    action   => 'TEST',
    title    => 'TEST',
    fields    => [qw/name color email/],
    submit   => [qw/Update Delete/],
    reset    => 0,
    template => {
        scalarref => \$template,
        type => 'HTC',
        variable => 'form',
        tagstyle => [qw(-classic -comment -asp +tt)],
        data => {
            script => $perlcode,
            template => $template,
            script => $0,
            perlcode => $perlcode,
        },
    },
    values   => { color => [qw/yellow green orange/] },
    validate => { color => [qw(red blue yellow pink)] },
);
my $mod = {
    color => {
        options => [[qw/red Red/],[qw/green Green/],[qw/ blue Blue/]],
        type => 'select',
    },
    size  => { value   => 42 }
};
while ( my ( $f, $o ) = each %{$mod} ) {
    $o->{name} = $f;
    $form->field(%$o);
}
my $out = $form->render;
print "$out\n";


__DATA__
<html><head><title>CGI::FormBuilder::Template::HTC example</title></head>
<body>
[%= form.jshead%]
[%= form.start%]
NAME:[%= form.field.name.field%]<br>
COLOR:[%= form.field.color.field %]<br>
SIZE:[%= form.field.size.value%]<br>
[%= form.submit%]<br>
[%= form.end%]

<h2>Script: [%= .script %]</h2><p>
<hr>
<h2>The Script:</h2>
<pre>
[%= perlcode escape=html %]
</pre>
</body></html>
