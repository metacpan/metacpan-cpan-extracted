package CGI::AppBuilder::Form;

# Perl standard modules
use strict;
use warnings;
use Getopt::Std;
use POSIX qw(strftime);
use Carp;
use CGI qw(:standard);
use CGI::AppBuilder;
use CGI::AppBuilder::Message qw(:echo_msg);

our $VERSION = 1.001;
require Exporter;
our @ISA         = qw(Exporter CGI::AppBuilder);
our @EXPORT      = qw();
our @EXPORT_OK   = qw(disp_form replace_named_variables 
    explode_variable explode_html
                   );
our %EXPORT_TAGS = (
    form => [qw(disp_form)],
    all  => [@EXPORT_OK]
);

=head1 NAME

CGI::AppBuilder::Form - Configuration initializer 

=head1 SYNOPSIS

  use CGI::AppBuilder::Form;

  my $ab = CGI::AppBuilder::Form->new(
     'ifn', 'my_init.cfg', 'opt', 'vhS:a:');
  my ($q, $ar, $ar_log) = $ab->start_app($0, \%ARGV);
  print $ab->disp_form($q, $ar); 

=head1 DESCRIPTION

This class provides methods for reading and parsing configuration
files. 

=cut

=head2 new (ifn => 'file.cfg', opt => 'hvS:')

This is a inherited method from CGI::AppBuilder. See the same method
in CGI::AppBuilder for more details.

=cut

sub new {
  my ($s, %args) = @_;
  return $s->SUPER::new(%args);
}

=head2 disp_form ($q, $ar)

Input variables:

  $q    - CGI object
  $ar   - array ref for parameters

Variables used or routines called:

  CGI::AppBuilder::Message
    echo_msg - echo messages
    set_param - get a parameter from hash array
  CGI::AppBuilder::Config
    eval_variables - replace value names with their values.

How to use:

  my $ifn = 'myConfig.ini';
  my ($q,$ar) = $s->get_inputs($ifn);
  $self->disp_form($q, $ar);

Return: none

This method expects the following varialbes in $ar:

  gk - GUI key items
  gi - GUI items
  gc - GUI columns
  gf - GUI form
  db - database connection varialbes (optional)
  vars_keep - variables separated by comma for hidden variables
  hr_form - hash ref containing attributes for <FORM> such as
    -target = "main"

This method performs the following tasks:

  1) checks whether GI, GC and GF variables being defined.
  2) replaces AR, DB, GI, and GC variables with their contents
  3) builds GF elements
  4) add hidden variables
  5) print the form

=cut

sub disp_form {
    my $s = shift;
    my ($q, $ar) = @_;

    # check required GUI variables
    foreach my $k (split /,/, 'gi,gc,gf') {
        # $s->echo_msg("    checking $k...", 3); 
        next if exists $ar->{$k};
        print h1("GUI element - {$k} is not defined");
        return;
    }
    if ($ar->{gi} =~ /db->/ && ! exists $ar->{db}) {
        print h1("GUI element - {db} is not defined");
        return;
    } 
    my $mvs = {};
    $mvs = $s->eval_variables($ar->{gk}, $ar) if exists $ar->{gk}; 
    $mvs = $s->eval_variables($ar->{gi}, $ar) if exists $ar->{gi}; 
    $mvs = $s->eval_variables($ar->{gc}, $ar) if exists $ar->{gc}; 
    $mvs = $s->eval_variables($ar->{gf}, $ar) if exists $ar->{gf}; 

    my $db = (exists $ar->{db} && $ar->{db}) ? $ar->{db} : {};
    my $pr = {ar=>$ar, db=>$db};
    $s->replace_named_variables($ar, 'ar,db,gk,gi,gc','gk,gi,gc,gf'); 

    my $gk = $s->explode_variable($ar, 'gk', $pr);
    $pr->{gk} = $gk;
    my $gi = $s->explode_variable($ar, 'gi', $pr);
    $pr->{gi} = $gi;

    # my $gi = eval $ar->{gi};
    if (!$gi) { 
        $s->echo_msg("GI is empty." ,1);    
    } elsif ($gi !~ /HASH/) {
        $s->echo_msg($ar->{gi},2);
        $s->echo_msg("GI not properly defined." ,1);
    } else {
        $s->explode_html($gi, $pr); 
    }
    # my $gc = eval $ar->{gc};
    my $gc = $s->explode_variable($ar, 'gc', $pr);
    $pr->{gc} = $gc;
    if ($gc !~ /HASH/ || ! exists $gc->{td}) {
        $s->echo_msg($ar->{gc},2);
        $s->echo_msg("GC not properly defined." ,1);
    } else {
        $s->echo_msg($ar->{gc},5);
        $s->echo_msg($gc,5);
    }
    $s->echo_msg($ar->{gf},5);
    # my $gf = eval $ar->{gf};
    my $gf = $s->explode_variable($ar, 'gf', $pr); 

    my $fmn = 'fm1';
       $fmn = $ar->{form_name}
         if exists $ar->{form_name} && $ar->{form_name};
    print "<center>\n";
    my %fr = (-name => $fmn, -method=>uc $ar->{method},
        -action=>"$ar->{action}?", -enctype=>$ar->{encoding} );
    if (exists $ar->{hr_form} && $ar->{hr_form}) {
        my $fr_hr = (ref($ar->{hr_form}) =~ /^HASH/) ? 
                    $ar->{hr_form} : eval $ar->{hr_form}; 
       foreach my $k (keys %{$fr_hr}) { $fr{$k} = $fr_hr->{$k}; }
    }
    print start_form(%fr);
    my $hvs = $s->set_param('vars_keep', $ar);
    if ($hvs) {
        foreach my $k (split /,/, $hvs) {
            my $v = $s->set_param($k, $ar);
            next if $v =~ /^\s*$/;
            print hidden($k,$v);
        }
    }
    print "$gf\n";
    print end_form;
    print "</center>\n";
    return;
}

=head2 explode_html ($gi, $pr)

Input variables:

  $gi   - a hash ref 
  $pr   - a parameter hash ref 

Variables used or routines called:

  CGI::AppBuilder::Message
    echo_msg - echo messages

How to use:

  my $ifn = 'myConfig.ini';
  my ($q,$ar) = $s->get_inputs($ifn);
  $self->explote_html($ar->{gi}, $ar);

Return: none

This method enables a 'x' command in your GUI definition and 
processes the complex elements in the hash ref. For 
instance, you have a GUI hash:

  gi = {   # GUI Items
    rts => ['rpt_src',['DataFax Generic','Study Specific'],
         'DataFax Generic'],
    xtd_rts => 'radio_group',
    act1 => td('Action'),
    act2 => td({-colspan=>'2',-align=>'center'},
          gk->{opf} . submit('a','Go') . ' ' . submit('a','Update') .
          ' ' . reset() ),
    xcp_act => 'act1,act2',
    act  => submit('a','Go') . ' ' . reset(),
    }

and the method will copy (xcp_act) the results (HTML text)
of $gi->{act1} and and $gi->{act2} into one. The $gi->{xcp_act}
will contains the combined string.

The 'xtd_' instructs the method to use $gi->{rts} as arguments for
the method name in $gi->{xtd_rts}. 

=cut

sub explode_html {
    my $s = shift;
    my ($gi, $pr) = @_;

    my $ar = (exists $pr->{ar}) ? $pr->{ar} : {};
    my $gk = (exists $pr->{gk}) ? $pr->{gk} : {};
    my $gc = (exists $pr->{gc}) ? $pr->{gc} : {};
    my $db = (exists $pr->{db}) ? $pr->{db} : {};
    foreach my $k (keys %$gi) {
        next if ($k !~ /^x(td|cp)_(.+)/i);
        my ($k1, $k2) = ($1, $2);
        if ($k1 =~ /^td/i) {
            my $tmp_ar = [];
            if (ref($gi->{$k2}) =~ /ARRAY/) {
                $tmp_ar = $gi->{$k2}; 
            } else {
                $tmp_ar = eval $gi->{$k2}; 
            }
            if ($gi->{$k} =~ /^radio_group/i) {
                $gi->{$k} = radio_group(@$tmp_ar);
            } elsif ($gi->{$k} =~ /^popup_menu/i) {
                $gi->{$k} = popup_menu(@$tmp_ar);
            } else {
                $gi->{$k} = td(@$tmp_ar);
            }
        } else {
            my $txt = "";
            foreach my $i (split /,/, $gi->{$k}) {
                $txt .= $gi->{$i};
            }
            $gi->{$k} = $txt;
        }
    }
    $s->echo_msg($gi,5);
    return;
}

=head2 explode_variable ($xr, $i, $pr)

Input variables:

  $xr - a hash ref such as the elements of gi,gk,gc,gf in 
        GUI hash array 
  $i  - one of gi, gk, gc and gf
  $pr - a parameter hash ref containing the values for $i to be
        used in $xr 

Variables used or routines called:

  CGI::AppBuilder::Message
    echo_msg - echo messages

How to use:

  my $ifn = 'myConfig.ini';
  my ($q,$ar) = $s->get_inputs($ifn);
  my $gi = $self->explode_variable($ar, 'gi', $ar);
  my $gc = $self->explode_variable($ar, 'gc', $ar);

Return: hash or hash ref for $i.

This method replaces variable names with their values and HTML
commands with their results.

=cut

sub explode_variable {
    my $s = shift;
    my ($xr, $i, $pr) = @_;
    my $hr = {};
    return wantarray ? %$hr : $hr if ! exists $xr->{$i};
    
    my $ar = (exists $pr->{ar}) ? $pr->{ar} : {};
    my $gi = (exists $pr->{gi}) ? $pr->{gi} : {};
    my $gk = (exists $pr->{gk}) ? $pr->{gk} : {};
    my $gc = (exists $pr->{gc}) ? $pr->{gc} : {};
    my $db = (exists $pr->{db}) ? $pr->{db} : {};
    if (ref($xr->{$i}) =~ /HASH/) {
        foreach my $k (keys %{$xr->{$i}}) {
            if (ref($xr->{$i}{$k}) =~ /^ARRAY/) { 
                for my $j (0..$#{$xr->{$i}{$k}}) {
                    $hr->{$k}[$j] = 
                    (ref($xr->{$i}{$k}[$j]) =~ /^(ARRAY|HASH)/) ? 
                    $xr->{$i}{$k}[$j] : eval $xr->{$i}{$k}[$j];
                }
            } elsif (ref($xr->{$i}{$k}) =~ /^HASH/) {
                foreach my $j (keys %{$xr->{$i}{$k}}) {
                    $hr->{$k}{$j} = 
                    (ref($xr->{$i}{$k}{$j}) =~ /^(ARRAY|HASH)/) ? 
                     $xr->{$i}{$k}{$j} : eval $xr->{$i}{$k}{$j};
                }
            } else { 
                $hr->{$k} = ($k =~ /^x(td|cp)/i) ? $xr->{$i}{$k} :
                    eval $xr->{$i}{$k}; 
            }
        }
    } else {
        $hr = eval $xr->{$i};
    }
    $s->echo_msg($hr,5);
    return wantarray ? %$hr : $hr; 
}

=head2 replace_named_variables ($ar, $vs, $ks)

Input variables:

  $ar - a hash ref containing the elements of gi,gk,gc,gf in 
        GUI hash array 
  $vs - a list of variable names separated by comma such as 
        'ar,db,gi,gk,gc'
  $ks - a list of key elements separated by comma such as
        'gk,gi,gc,gf'

Variables used or routines called:

  None

How to use:

  my $ifn = 'myConfig.ini';
  my ($q,$ar) = $s->get_inputs($ifn);
  $self->replace_named_variables($ar, 'ar,db,gk,gi,gc','gk,gi,gc,gf'); 

Return: None.

This method replaces named variables with their values in $ar.

=cut

sub replace_named_variables {
    my $s = shift;
    my ($ar, $vs, $ks) = @_;

    return if !$vs || !$ks; 
    $vs =~ s/\s+//g; $ks =~ s/\s+//g;  # remove any blanks

    foreach my $v (split /,/, $vs) {     # variables: ar,db,gk,gi,gc
        foreach my $k (split /,/, $ks) { # keys: gk,gi,gc,gf
            next if ! exists $ar->{$k}; 
            $ar->{$k} =~ s/$v\->/\$$v->/g if ref($ar->{$k}) !~ /^HASH/;
            next                          if ref($ar->{$k}) !~ /^HASH/;
            foreach my $i (keys %{$ar->{$k}}) {
                if (ref($ar->{$k}{$i}) !~ /^(ARRAY|HASH)/) {
                    $ar->{$k}{$i} =~ s/$v\->/\$$v->/g;
                    next;
                } 
                if (ref($ar->{$k}{$i}) =~ /^ARRAY/) { 
                    for my $j (0..$#{$ar->{$k}{$i}}) {
                        $ar->{$k}{$i}[$j] =~ s/$v\->/\$$v->/g;
                    }
                } else {
                    for my $j (keys %{$ar->{$k}{$i}}) {
                        $ar->{$k}{$i}{$j} =~ s/$v\->/\$$v->/g;
                    }
                }
            }
        }
    }
    return;
}

1;

=head1 HISTORY

=over 4

=item * Version 0.10

This version extracts the disp_form method from CGI::Getopt class, 
inherits the new constructor from CGI::AppBuilder, and adds
new methods of replace_named_variables, explode_variable, and 
explode_html.

=item * Version 0.20

=cut

=head1 SEE ALSO (some of docs that I check often)

Oracle::Loader, Oracle::Trigger, CGI::Getopt, File::Xcopy,
CGI::AppBuilder, CGI::AppBuilder::Message, CGI::AppBuilder::Log,
CGI::AppBuilder::Config, etc.

=head1 AUTHOR

Copyright (c) 2005 Hanming Tu.  All rights reserved.

This package is free software and is provided "as is" without express
or implied warranty.  It may be used, redistributed and/or modified
under the terms of the Perl Artistic License (see
http://www.perl.com/perl/misc/Artistic.html)

=cut

