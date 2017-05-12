package Dancer::Plugin::FontSubset;
BEGIN {
  $Dancer::Plugin::FontSubset::AUTHORITY = 'cpan:YANICK';
}
{
  $Dancer::Plugin::FontSubset::VERSION = '0.1.2';
}
# ABSTRACT: Generate font subsets on-the-fly


use 5.12.0;

use Dancer ':syntax';
use Dancer::Plugin;

use List::AllUtils qw/ uniq /;
use Font::TTF::Font;
use Font::TTF::Scripts::Name;

use Moo;
with 'MooX::Singleton';

has _config => (
    is => 'ro',
    lazy => 1,
    default => sub { 
        plugin_setting;
    },
);

has fonts_dir => (
    is => 'ro',
    lazy => 1,
    default => sub {
        $_[0]->_config->{fonts_dir} || 'public/fonts';
    },
);

has font_base_url => (
    is => 'ro',
    lazy => 1,
    default => sub {
        $_[0]->_config->{font_base_url} || '/font';
    },
);

has use_cache => (
    is => 'ro',
    lazy => 1,
    default => sub {
        $_[0]->_config->{use_cache};
    },
);

my $plugin = __PACKAGE__->instance;

# do we need Cache::CHI?
if ( $plugin->use_cache ) {
    eval "use Dancer::Plugin::Cache::CHI; 1"
        or die $@;
}

sub font_path {
    $plugin->fonts_dir . '/' . $_[1];
}

get $plugin->font_base_url . '/subset.js' => sub {

    return sprintf <<'END_JS', $plugin->font_base_url;
$(function(){
    $('.subfont').each(function(){
        var characters = $(this).text().split('').sort();
        characters = characters.filter(function(e,i,a){ 
            return characters.lastIndexOf(e) == i 
        }).join('');
        var family = $(this).attr('data-font') + '-' + characters;
        var style = "@font-face { font-family: " + family 
            + "; src: url('%s/" + $(this).attr('data-font') + ".ttf?t=" + characters 
            + "'); }";
        $('body').append( "<style>"+style+"</style>" );
        $(this).css('font-family', family);
    });
});
END_JS

};

get $plugin->font_base_url() . '/:fontname' => sub {
    my $fontname = param('fontname');

    $fontname =~ s#\.\.##g; # just to be safe

    my $path = $plugin->font_path( $fontname );

    send_error 'font not found', 404 unless -f $path;

    # no text? No job to do
    my $text = param('t') //
        return send_file $path, system_path => 1;

    my @chars = map { ord } sort { $a cmp $b } uniq split //, $text; 

    my $output = generate_subfont( $path, @chars );

    return send_file \$output, content_type => 'application/x-ttf';
};

my $_generate_subfont = sub {
    my( $path, @chars ) = @_;

    my $f = Font::TTF::Font->open($path);

    my $cmap = $f->{'cmap'}->read->find_ms;
    my $post = $f->{'post'}->read;
    my $subsetter = Font::TTF::Scripts::SubSetter->new;

    for my $char ( @chars ) {
        $subsetter->add_glyph( $cmap->{val}{$char} )
            if $cmap->{val}{$char};
    }

    my $canchangegids = 1;
    my $numg = $f->{'maxp'}{'numGlyphs'};
    $f->tables_do(sub {$canchangegids |= $_[0]->canchangegids();});
    $numg = $subsetter->creategidmap($f) if ($canchangegids);

    $f->{'loca'}->subset($subsetter);
    $f->tables_do(sub {$_[0]->subset($subsetter);});
    $f->{'maxp'}{'numGlyphs'} = $subsetter->{'gcount'};
    $f->tables_do(sub {$_[0]->update;});
    open my $fh, '>', \my $output;

    $f->out($fh);

    return $output;
};

if( $plugin->use_cache ) {
    *generate_subfont = sub {
        my @args = @_;
        Dancer::Plugin::Cache::CHI::cache()->compute( 'font-' . $args[0] . '-' . join( '', @args[1..$#args] ), sub {
            $_generate_subfont->(@args);
        });
    };
}
else {
    *generate_subfont = sub {
        $_generate_subfont->(@_);
    };
}


register_plugin;

true;

# all shamelessly ripped off from 'ttfsubset' from
# TTF::Font::TTF

package 
    Font::TTF::Scripts::SubSetter;

sub new
{
    my ($class) = @_;
    my ($self) = {};
    $self->{'glyphs'} = '';
    $self->{'remaps'} = {};
    bless $self, $class || ref $class;
    foreach (0..2) { $self->add_glyph($_); }
    return $self;
}

sub add_glyph
{
    my ($self, $n, $private) = @_;
    if (($private && !$self->{'gidmap'}[$n]) || (!$private && !vec($self->{'glyphs'}, $n, 1)))
    {
        vec($self->{'glyphs'}, $n, 1) = 1; # unless ($private);
        $self->{'gidmap'}[$n] = $self->{'gcount'}++ if (defined $self->{'gidmap'});
        return 1;
    }
    else
    { return 0; }
}

sub keep_glyph
{
    my ($self, $n) = @_;
    return vec($self->{'glyphs'}, $n, 1);
}

sub remap
{
    my ($self, $u, $n) = @_;
    $self->{'remaps'}{$u} = $n;
}

sub langlist
{
    my ($self, @dat) = @_;
    $self->{'langs'} = { map {$_=>1} @dat };
}

sub scriptlist
{
    my ($self, @dat) = @_;
    $self->{'scripts'} = { map {$_=>1} @dat };
}

sub creategidmap
{
    my ($self, $font) = @_;
    my ($numg) = $font->{'maxp'}{'numGlyphs'};
    my ($count) = 0;

    $self->{'gidmap'} = [];
    $self->{'gcount'} = 0;
    foreach my $i (0 .. $numg - 1)
    { push (@{$self->{'gidmap'}}, vec($self->{'glyphs'}, $i, 1) ? $self->{'gcount'}++ : 0); }
    return $self->{'gcount'};
}

sub map_glyph
{
    my ($self, $g) = @_;
    # no glyph remapping yet
    if ($self->{'gidmap'})
    { return $self->{'gidmap'}[$g]; }
    else
    { return $g; }
}

package 
    Font::TTF::Table;

sub canchangegids
{ 1; }

sub subset
{
    my ($self, $subsetter) = @_;
    return 0 if ($self->{' subsetdone'});
    $self->{' subsetdone'} = 1;
    $self->read;
    $self->dirty;
    return 1;
}

package     
    Font::TTF::Loca;

sub subset
{
    my ($self, $subsetter) = @_;
    my ($res) = [];
    my ($i, $vec);

    return unless ($self->SUPER::subset($subsetter));
    for ($i = 0; $i < @{$self->{'glyphs'}}; $i++)
    {
        if ($subsetter->keep_glyph($i))
        { $self->outglyph($subsetter, $res, $i); }
    }
    $self->{'glyphs'} = $res;
}

sub outglyph
{
    my ($self, $subsetter, $res, $n) = @_;

    $res->[$subsetter->map_glyph($n)] = $self->{'glyphs'}[$n];
    if (defined $self->{'glyphs'}[$n] && $self->{'glyphs'}[$n]->read()->{'numberOfContours'} < 0)
    {
        my ($g) = $self->{'glyphs'}[$n]->read_dat();
        foreach my $c (@{$g->{'comps'}})
        {
            if ($subsetter->add_glyph($c->{'glyph'}, 1))
            { $self->outglyph($subsetter, $res, $c->{'glyph'}); }
            $c->{'glyph'} = $subsetter->map_glyph($c->{'glyph'});
        }
        $g->{' isDirty'} = 1;
    }
}

package 
    Font::TTF::Ttopen;

sub subset
{
    my ($self, $subsetter) = @_;
    return unless ($self->SUPER::subset($subsetter));

    my ($l, $count, @lmap, @lookups, $lkvec, $res, $nlookup);
    $lkvec = "";
    $nlookup = $#{$self->{'LOOKUP'}};
    # process non-contextual lookups
    foreach $l (0 .. $nlookup)
    {
        my ($type) = $self->{'LOOKUP'}[$l]{'TYPE'};
        next if ($type >= $self->extension() - 2 && $type < $self->extension());
        $res = $self->subset_lookup($self->{'LOOKUP'}[$l]);

        if (!@{$res})
        {
            delete $self->{'LOOKUP'}[$l];
            vec($lkvec, $l, 1) = 0;
        }
        else
        {
            $self->{'LOOKUP'}[$l]{'SUB'} = $res;
            vec($lkvec, $l, 1) = 1;
        }
    }
    # now process contextual lookups knowing whether the other lookup is there
    # also collect the complete lookup list now
    foreach $l (0 .. $nlookup)
    {
        if (defined $self->{'LOOKUP'}[$l])
        {
            my ($type) = $self->{'LOOKUP'}[$l]{'TYPE'};
            if ($type >= $self->extension() - 2 && $type < $self->extension())
            {
                $res = $self->subset_lookup($self->{'LOOKUP'}[$l], $lkvec);
                if (!@{$res})
                {
                    delete $self->{'LOOKUP'}[$l];
                    vec($lkvec, $l, 1) = 0;
                }
                else
                {
                    $self->{'LOOKUP'}[$l]{'SUB'} = $res;
                    vec($lkvec, $l, 1) = 1;
                }
            }
        }
        if (vec($lkvec, $l, 1))
        {
            push (@lookups, $self->{'LOOKUP'}[$l]);
            push (@lmap, $count++);
        }
        else
        { push (@lmap, -1); }
    }
    
    $self->{'LOOKUP'} = \@lookups;
    foreach $l (@lookups)
    { $self->fixcontext($l, \@lmap); }

    foreach my $t (@{$self->{'FEATURES'}{'FEAT_TAGS'}})
    {
        my $f = $self->{'FEATURES'}{$t};
        foreach $l (0 .. $#{$f->{'LOOKUPS'}})
        {
            my ($v) = $lmap[$f->{'LOOKUPS'}[$l]];
            if ($v < 0)
            { delete $f->{'LOOKUPS'}[$l]; }
            else
            { $f->{'LOOKUPS'}[$l] = $v; }
        }
        if (!@{$f->{'LOOKUPS'}})
        { delete $self->{'FEATURES'}{$t}; }
        else
        { $f->{'LOOKUPS'} = [grep {defined $_} @{$f->{'LOOKUPS'}}]; }
    }
    $self->{'FEATURES'}{'FEAT_TAGS'} = [grep {defined $self->{'FEATURES'}{$_}} @{$self->{'FEATURES'}{'FEAT_TAGS'}}];

    my ($isEmpty) = 1;
    foreach my $s (keys %{$self->{'SCRIPTS'}})
    {
        foreach $l (-1 .. $#{$self->{'SCRIPTS'}{$s}{'LANG_TAGS'}})
        {
            my $lang;
            if ($l < 0)
            { $lang = $self->{'SCRIPTS'}{$s}{'DEFAULT'}; }
            else
            { $lang = $self->{'SCRIPTS'}{$s}{$self->{'SCRIPTS'}{$s}{'LANG_TAGS'}[$l]}; }

            if (defined $lang->{'FEATURES'})
            {
                foreach my $i (0 .. @{$lang->{'FEATURES'}})
                {
                    if (!defined $self->{'FEATURES'}{$lang->{'FEATURES'}[$i]})
                    { delete $lang->{'FEATURES'}[$i]; }
                }
                $lang->{'FEATURES'} = [grep {$_} @{$lang->{'FEATURES'}}];
            }
            if (defined $lang->{'DEFAULT'} && $lang->{'DEFAULT'} >= 0)
            {
                my ($found) = 0;
                foreach my $f (@{$self->{'FEATURES'}{'FEAT_TAGS'}})
                {
                    if ($self->{'FEATURES'}{$f}{'INDEX'} == $lang->{'DEFAULT'})
                    {
                        $found = 1;
                        last;
                    }
                }
                if (!$found)
                { $lang->{'DEFAULT'} = -1; }
            }
            if (($l >= 0 && defined $subsetter->{'langs'}
                && !defined $subsetter->{'langs'}{$self->{'SCRIPTS'}{$s}{'LANG_TAGS'}[$l]})
                    || ((!defined $lang->{'FEATURES'} || !@{$lang->{'FEATURES'}})
                        && (!defined $lang->{'DEFAULT'} || $lang->{'DEFAULT'} < 0)))
            {
                if ($l < 0)
                { delete $self->{'SCRIPTS'}{$s}{'DEFAULT'}; }
                else
                {
                    delete $self->{'SCRIPTS'}{$s}{$self->{'SCRIPTS'}{$s}{'LANG_TAGS'}[$l]};
                    delete $self->{'SCRIPTS'}{$s}{'LANG_TAGS'}[$l];
                }
            }
        }
        if ((defined $subsetter->{'scripts'} && !defined $subsetter->{'scripts'}{$s})
                || (!@{$self->{'SCRIPTS'}{$s}{'LANG_TAGS'}} && !defined $self->{'SCRIPTS'}{$s}{'DEFAULT'}))
        {
            delete $self->{'SCRIPTS'}{$s};
            next;
        }
        else
        { $isEmpty = 0; }
    }
    if ($isEmpty)
    {
        my ($k, $v);
        while (($k, $v) = each %{$self->{' PARENT'}})
        {
            if ($v eq $self)
            {
                delete $self->{' PARENT'}{$k};
                last;
            }
        }
    }
}

sub subset_lookup
{
    my ($self, $lookup, $lkvec) = @_;
    my ($s, $l);
    my ($res) = [];

    foreach $s (@{$lookup->{'SUB'}})
    {
        if (!$self->subset_subtable(undef, $s, $lookup, $lkvec)
            || !defined $s->{'RULES'} || !@{$s->{'RULES'}})
        { next; }
        $s->{'RULES'} = [grep {$_} @{$s->{'RULES'}}];
        # remove unused coverage indices
        if ($s->{'COVERAGE'})
        {
            my $c = $s->{'COVERAGE'}{'val'};
            my $i = 0;
            foreach my $k (sort {$c->{$a} <=> $c->{$b}} keys %{$c})
            { $c->{$k} = $i++; }
        }
        push (@{$res}, $s);
    }
    return $res;
}


sub subset_class
{
    my ($self, $subsetter, $classdef, $noremap) = @_;
    my ($res) = [];
    my ($count) = 0;
    my ($class) = $classdef->{'val'};

    foreach (sort {$a <=> $b} keys %{$class})
    {
        if (!$subsetter->keep_glyph($_))
        { delete $class->{$_}; }
        else
        {
            my $g = $subsetter->map_glyph($_);
            $class->{$g} = delete $class->{$_};
            $res->[$class->{$g}] = ++$count unless (defined $res->[$class->{$g}])
        }
    }
    # remap the class
    unless ($noremap)
    {
        foreach (keys %{$class})
        { $class->{$_} = $res->[$class->{$_}]; }
    }
    if (@{$res})
    { return $res; }
    else
    { return undef; }
}

sub subset_cover
{
    my ($self, $subsetter, $coverage, $rules) = @_;
    return $coverage if (defined $coverage->{'isremapped'});
    my $isEmpty = 1;
    my $cover = $coverage->{'val'};
    foreach (sort {$a <=> $b} keys %{$cover})
    {
        if (!$subsetter->keep_glyph($_))
        {
            delete $rules->[$cover->{$_}] if $rules;
            delete $cover->{$_};
        }
        else
        {
            $cover->{$subsetter->map_glyph($_)} = delete $cover->{$_};
            $isEmpty = 0;
        }
    }
    if ($isEmpty)
    { return undef; }
    else
    {
        $coverage->{'isremapped'} = 1;
        return $coverage;
    }
}

sub subset_string
{
    my ($self, $subsetter, $string, $fmt, $classvals) = @_;
    my ($test) = 1;

    return 0 if ($fmt == 2 && !$classvals);
    foreach (@{$string})
    {
        if ($fmt == 1 && $subsetter->keep_glyph($_))
        { $_ = $subsetter->map_glyph($_); }
        elsif ($fmt == 2 && defined $classvals->[$_])
        { $_ = $classvals->[$_]; }
        elsif ($fmt == 3 && $self->subset_cover($subsetter, $_, undef))
        { }
        else
        {
            $test = 0;
            last;
        }
    }
    return $test;
}

sub subset_context
{
    my ($self, $subsetter, $sub, $type, $lkvec) = @_;
    my ($fmt) = $sub->{'FORMAT'};
    my ($classvals, $prevals, $postvals, $i, $j, @gids);

    return 0 if (defined $sub->{'COVERAGE'} && !$self->subset_cover($subsetter, $sub->{'COVERAGE'}, $fmt < 2 ? $sub->{'RULES'} : undef));
    while (my ($k, $v) = each %{$sub->{'COVERAGE'}{'val'}})
    { $gids[$v] = $k; }
    return 0 if (defined $sub->{'CLASS'} && !($classvals = $self->subset_class($subsetter, $sub->{'CLASS'})));
    return 0 if (defined $sub->{'PRE_CLASS'} && !($prevals = $self->subset_class($subsetter, $sub->{'PRE_CLASS'})));
    return 0 if (defined $sub->{'POST_CLASS'} && !($postvals = $self->subset_class($subsetter, $sub->{'POST_CLASS'})));
    # tidy up coverage tables that contain glyphs not in the matching class
#    if (defined $sub->{'CLASS'})
#    {
#        foreach $i (0 .. $#gids)
#        {
#            if (defined $gids[$i] && !defined $sub->{'CLASS'}{'val'}{$gids[$i]})
#            {
#                delete $sub->{'COVERAGE'}{'val'}{$gids[$i]};
#                delete $gids[$i];
#            }
#        }
#        @gids = grep {defined $_} @gids;
#    }
#    return 0 unless (@gids);


    foreach $i (0 .. @{$sub->{'RULES'}})
    {
        my ($isEmpty) = 1;
        if ($sub->{'RULES'}[$i])
        {
            foreach $j (0 .. $#{$sub->{'RULES'}[$i]})
            {
                my ($r) = $sub->{'RULES'}[$i][$j];
                my ($test) = 1;
                if ($type == 4)
                {
                    if ($subsetter->keep_glyph($r->{'ACTION'}[0]))
                    { $r->{'ACTION'}[0] = $subsetter->map_glyph($r->{'ACTION'}[0]); }
                    else
                    { $test = 0; }
                }
                else
                {
                    foreach my $k (0 .. $#{$sub->{'RULES'}[$i][$j]{'ACTION'}})
                    {
                        my $a = $sub->{'RULES'}[$i][$j]{'ACTION'}[$k];
                        if (!vec($lkvec, $a->[1], 1))
                        { delete $sub->{'RULES'}[$i][$j]{'ACTION'}[$k]; }
                    }
                    $test = (@{$sub->{'RULES'}[$i][$j]{'ACTION'}} != 0);
                }
                if ($test && $type == 6 && defined $r->{'PRE'})
                { $test = $self->subset_string($subsetter, $r->{'PRE'}, $fmt, $prevals); }
                if ($test && $type == 6 && defined $r->{'POST'})
                { $test = $self->subset_string($subsetter, $r->{'POST'}, $fmt, $postvals); }
                if ($test)
                { $test = $self->subset_string($subsetter, $r->{'MATCH'}, $fmt, $classvals); }
                if (!$test)
                { delete $sub->{'RULES'}[$i][$j]; }
                else
                { $isEmpty = 0; }
            }
            $sub->{'RULES'}[$i] = [grep {$_} @{$sub->{'RULES'}[$i]}];
        }
        if ($isEmpty)
        {
            delete $sub->{'RULES'}[$i];
            delete $sub->{'COVERAGE'}{'val'}{$gids[$i]} if ($fmt < 2);  # already remapped
        }
    }
    return 1;
}

sub fixcontext
{
    my ($self, $l, $lmap) = @_;

    return if ($l->{'TYPE'} < $self->extension() - 2 || $l->{'TYPE'} >= $self->extension());
    foreach my $s (@{$l->{'SUB'}})
    {
        foreach my $r (@{$s->{'RULES'}})
        {
            foreach my $p (@{$r})
            {
                foreach my $b (@{$p->{'ACTION'}})
                { $b->[1] = $lmap->[$b->[1]]; }
            }
        }
    }
}



package 
    Font::TTF::GSUB;

sub subset_subtable
{
    my ($self, $subsetter, $sub, $lookup, $lkvec) = @_;
    my ($type) = $lookup->{'TYPE'};
    my ($fmt) = $sub->{'FORMAT'};
    my ($r, $i, $j, @gids, $k, $v);

    return 0 if ($type < 4 && !$self->subset_cover($subsetter, $sub->{'COVERAGE'}, $sub->{'RULES'}));

    while (($k, $v) = each %{$sub->{'COVERAGE'}{'val'}})
    { $gids[$v] = $k; }

    if (($type == 1 && $fmt > 1) || $type == 2)
    {
        foreach $i (0 .. $#{$sub->{'RULES'}})
        {
            next unless (defined $sub->{'RULES'}[$i]);
            foreach my $k (0 .. $#{$sub->{'RULES'}[$i][0]{'ACTION'}})
            {
                $j = $sub->{'RULES'}[$i][0]{'ACTION'}[$k];
                if (!$subsetter->keep_glyph($j))
                {
                    delete $sub->{'RULES'}[$i];
                    delete $sub->{'COVERAGE'}{'val'}{$gids[$i]}; # already remapped
                    last;
                }
                else
                { $sub->{'RULES'}[$i][0]{'ACTION'}[$k] = $subsetter->map_glyph($j); }
            }
        }
    }
    elsif ($type == 3)
    {
        foreach $i (0 .. $#{$sub->{'RULES'}})
        {
            if (!defined $sub->{'RULES'}[$i])
            {
                delete $sub->{'COVERAGE'}{'val'}{$gids[$i]};
                next;
            }
            my $res = [];
            foreach $j (@{$sub->{'RULES'}[$i][0]{'ACTION'}})
            {
                if ($subsetter->keep_glyph($j))
                { push (@{$res}, $subsetter->map_glyph($j)); }
            }
            if (@{$res})
            { $sub->{'RULES'}[$i][0]{'ACTION'} = $res; }
            else
            {
                delete $sub->{'RULES'}[$i];
                delete $sub->{'COVERAGE'}{'val'}{$gids[$i]};  # already remapped
            }
        }
    }
    elsif ($type >=4 && $type <= 6)
    { return $self->subset_context($subsetter, $sub, $type, $lkvec); }
    return 1;
}

package 
    Font::TTF::GPOS;

sub subset_subtable
{
    my ($self, $subsetter, $sub, $lookup, $lkvec) = @_;
    my ($type) = $lookup->{'TYPE'};
    my ($fmt) = $sub->{'FORMAT'};
    my (@gids) = sort { $a <=> $b} keys %{$sub->{'COVERAGE'}{'val'}};
    my ($i, $j, $k);

    return 0 if ($type <= 6 && !$self->subset_cover($subsetter, $sub->{'COVERAGE'}, $sub->{'RULES'}));
    if ($type == 2 && $fmt == 1)
    {
        foreach $i (0 .. $#{$sub->{'RULES'}})
        {
            foreach $j (0 .. $#{$sub->{'RULES'}[$i]})
            {
                my ($r) = $sub->{'RULES'}[$i][$j];
                if (!$subsetter->keep_glyph($r->{'MATCH'}[0]))
                { delete $sub->{'RULES'}[$i][$j]; }
                else
                { $r->{'MATCH'}[0] = $subsetter->map_glyph($r->{'MATCH'}[0]); }
            }
            if (!@{$sub->{'RULES'}[$i]})
            { delete $sub->{'RULES'}[$i]; }
            else
            { $sub->{'RULES'}[$i] = [grep {$_} @{$sub->{'RULES'}[$i]}]; }
        }
    }
    elsif ($type == 2 && $fmt == 2)
    {
        my ($c1vals) = $self->subset_class($subsetter, $sub->{'CLASS'});
        my ($c2vals) = $self->subset_class($subsetter, $sub->{'MATCH'}[0]);
        my ($nrules) = [];
        
        foreach $i (0 .. $#{$sub->{'RULES'}})
        {
            if (!$c1vals->[$i])
            { delete $sub->{'RULES'}[$i]; }
            else
            {
                my (@nrule);
                foreach $j (0 .. $#{$sub->{'RULES'}[$i]})
                {
                    if (!defined $c2vals->[$j])
                    { delete $sub->{'RULES'}[$i][$j]; }
                    else
                    { $nrule[$c2vals->[$j]] = $sub->{'RULES'}[$i][$j]; }
                }
                if (@nrule)
                { $nrules->[$c1vals->[$i]] = [grep {$_} @nrule]; }
            }
        }
        if (@{$nrules})
        { $sub->{'RULES'} = $nrules; }
        else
        { return 0; }
    }
    elsif ($type >= 4 && $type <= 6)
    { return $self->subset_cover($subsetter, $sub->{'MATCH'}[0], $sub->{'MARKS'}) ? 1 : 0; }
    elsif ($type >=7 && $type <= 8)
    { return $self->subset_context($subsetter, $sub, $type - 2, $lkvec); }
    return 1;
}

package 
    Font::TTF::GDEF;

sub subset
{
    my ($self, $subsetter) = @_;

    return unless ($self->SUPER::subset($subsetter));
    if (defined $self->{'GLYPH'})
    { delete $self->{'GLYPH'} unless (Font::TTF::Ttopen->subset_class($subsetter, $self->{'GLYPH'}, 1)); }
    if (defined $self->{'ATTACH'})
    { delete $self->{'ATTACH'} unless (Font::TTF::Ttopen->subset_cover($subsetter, $self->{'ATTACH'}{'COVERAGE'}, $self->{'ATTACH'}{'POINTS'})); }
    if (defined $self->{'LIG'})
    { delete $self->{'LIG'} unless (Font::TTF::Ttopen->subset_cover($subsetter, $self->{'LIG'}{'COVERAGE'}, $self->{'LIG'}{'POINTS'})); }
    if (defined $self->{'MARKS'})
    { delete $self->{'MARKS'} unless (Font::TTF::Ttopen->subset_cover($subsetter, $self->{'MARKS'}, undef)); }
}

package 
    Font::TTF::Cmap;

sub subset
{
    my ($self, $subsetter) = @_;

    return unless ($self->SUPER::subset($subsetter));
    foreach my $i (0 .. $#{$self->{'Tables'}})
    {
        my ($t) = $self->{'Tables'}[$i]{'val'};
        foreach my $k (keys %{$t})
        {
            if ($subsetter->keep_glyph($t->{$k}))
            { $t->{$k} = $subsetter->map_glyph($t->{$k}); }
            else
            { delete $t->{$k}; }
        }
        if ($self->is_unicode($i))
        {
            foreach my $k (keys %{$subsetter->{'remaps'}})
            { $t->{$k} = $subsetter->map_glyph($subsetter->{'remaps'}{$k}); }
        }
    }
}

package 
    Font::TTF::Post;

no warnings;

sub subset
{
    my ($self, $subsetter) = @_;
    my ($res) = [];

    return unless ($self->SUPER::subset($subsetter));
    # need to rewrite for real glyph remapping
    foreach my $i (0 .. @{$self->{'VAL'}})
    { $res->[$subsetter->map_glyph($i)] = $subsetter->keep_glyph($i) ? $self->{'VAL'}[$i] : ".notdef"; }
    $self->{'VAL'} = $res;
}

package 
    Font::TTF::Hmtx;

sub subset
{
    my ($self, $subsetter) = @_;
    my ($adv) = [];
    my ($lsb) = [];

    return unless ($self->SUPER::subset($subsetter));
    for (my $i = 0; $i < @{$self->{'advance'}}; $i++)
    {
        if ($subsetter->keep_glyph($i))
        {
            my ($g) = $subsetter->map_glyph($i);
            $adv->[$g] = $self->{'advance'}[$i];
            $lsb->[$g] = $self->{'lsb'}[$i];
        }
    }
    $self->{'advance'} = $adv;
    $self->{'lsb'} = $lsb;
}

package 
    Font::TTF::LTSH;

sub subset
{
    my ($self, $subsetter) = @_;
    my ($res) = [];

    return unless ($self->SUPER::subset($subsetter));
    for (my $i = 0; $i < @{$self->{'glyphs'}}; $i++)
    {
        if ($subsetter->keep_glyph($i))
        { $res->[$subsetter->map_glyph($i)] = $self->{'glyphs'}[$i]; }
    }
    $self->{'glyphs'} = $res;
    $self->{'Num'} = $subsetter->{'gcount'};
}


package 
    Font::TTF::Gloc;

sub canchangegids
{ 0; }

__END__

=pod

=head1 NAME

Dancer::Plugin::FontSubset - Generate font subsets on-the-fly

=head1 VERSION

version 0.1.2

=head1 SYNOPSIS

In config.yml:

    plugins:
        FontSubset:
            fonts_dir:      public/fonts
            font_base_url:  /font
            use_cache:      0

In the app:

    package MyApp;

    use Dancer;
    use Dancer::Plugin::FontSubset;

    ...

in the template:

    <html>
    <head>
        <script src="/javascripts/jquery.js"></script>
        <script src="/font/subset.js"></script>
    </head>
    <body>
        <h1 class="subfont" data-font="my_font">Hi there</h1>
    </body>

=head1 DESCRIPTION

I<Dancer::Plugin::FontSubset> generate subsets of the glyphs of given fonts,
a little like what L<Google Font
provides|https://developers.google.com/fonts/docs/getting_started#Optimizing_Requests>.
Currently, I<Dancer::Plugin::FontSubset> only works for a subset TTF fonts. Always test that any
given font will work well with the plugin before throwing it in a production
system.

=head2 Basic Usage

to use this plugin, put your fonts in the directory C<public/fonts>. The
original font file can be accessed via the url C</fonts/thefont.tff> (natch),
and its subsets via the route C</font/thefont.ttf?t=abc>, where the characters 
to be included in the subset are passed via the I<t> parameter. For example,
the url required to generate the font subset required to render 'Hello world'
would be C</font/thefont.ttf?t=%20Helowrd> (including the whitespace (%20) is 
important, as it is often a glyph by its own right).

=head2 JQuery Helping Script

A JQuery utility script is also available at C</font/subset.js>. If the script
is loaded by a page, it will find all elements having the I<subfont> class,
generate the characters required and query the application for the subset of
whichever font provided in the I<data-font> attribute. In other words, 

    <html>
    <head>
        <script src="/javascripts/jquery.js"></script>
        <script src="/font/subset.js"></script>
    </head>
    <body>
        <h1 class="subfont" data-font="my_font">Hi there</h1>
    </body>
    </html>

is all that is required to have the C<h1> element of this document 
rendered using the appropriate subset of the C<my_font.ttf> font.

=head2 Caching

To improve performance you can enable caching, which will use 
L<Dancer::Plugin::Cache::CHI> to cache the generated font subsets.

=head1 CONFIGURATION PARAMETERS

=head2 fonts_dir

The system directory containing the fonts. Defaults to C<public/fonts>.

=head2 font_base_url

The root route for the subset fonts. Defaults to C</font>.

=head2 use_cache

Boolean indicating if caching should be used. Defaults to I<false>. If set to
true, the application will also use L<Dancer::Plugin::Cache::CHI>.

=head1 SEE ALSO

L<Font::TTF::Font>

=head1 AUTHOR

Yanick Champoux <yanick@babyl.dyndns.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
