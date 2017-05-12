#
# $Id: ApacheOutputFastTemplate.pm,v 1.5 2005/01/27 23:30:50 scottb Exp $
#

package CGI::CRUD::ApacheOutputFastTemplate;

use strict;
use CGI::AutoForm;
use CGI::FastTemplate;
use CGI::CRUD::Output;

@CGI::CRUD::ApacheOutputFastTemplate::ISA = qw(CGI::CRUD::Output);


# CGI::FastTemplate path for templates
# May override by setting CRUDDY_FAST_TEMPLATE_PATH env
# variable (e.g. SetEnv or PerlSetEnv)
my $DEFAULT_TPL_PATH = '/var/www/tpl';

# CGI::FastTemplate 'main' template
# May override by setting CRUDDY_FAST_TEMPLATE_MAIN env
# variable (e.g. SetEnv or PerlSetEnv)
# -or-
# as a second argument to the C<output> method call
my $DEFAULT_TPL_MAIN = 'cruddy.tpl';

#
# Use in conjunction with mod_perl_debug.pl
# NOTE!
# Do not use in production sites
#
my $PARAMDUMP = $ENV{CRUDDY_PARADUMP_DEBUG};


if ($PARAMDUMP)
{
    # To convert carps to clucks ...
    #CGI::LogCarp::import( 'verbose' );
}


sub new
{
    my $caller = shift;
    my ($r,$defaults) = @_;

    my $self = $caller->SUPER::new(@_);

    if ($ENV{MOD_PERL})
    {
        $self->{apache} = $r;
        $self->{user} = $r->user() || $ENV{CRUDDY_DEFAULT_USER};

        # Save the Apache Request instance so its methods can be
        # accessed later.
        $self->{apreq} = $::MOD_PERL_REQ_CLASS->new($r);

        my @pars = $self->{apreq}->param();
        my %query;
        foreach my $par (@pars)
        {
            my @t = $self->{apreq}->param($par);
            if (@t > 1)
            {
                $query{uc($par)} = \@t;
            }
            else
            {
                $query{uc($par)} = $t[0];
            }
        }
        $self->{q} = \%query;

        if ($ENV{CRUDDY_PARADUMP_DEBUG})
        {
            require "Data/Dumper.pm";
            open(PDUMP,">$ENV{CRUDDY_PARADUMP_DEBUG}") || die($!);
            print PDUMP Data::Dumper::Dumper(\%query);
            print PDUMP "1;\n";
            close(PDUMP);
        }
    }
    else
    {
        $self->{user} = $r->[1];
        my %t = ();
        if (ref($::VAR1) eq 'HASH')
        {
            %t = %$::VAR1;
        }
        my $i = 0;
        my %q;
        while (defined(${$r->[0]}[$i]))
        {
            my $key = uc(${$r->[0]}[$i]);
            my $val = ${$r->[0]}[++$i];
            push(@{$q{$key}},$val);
            $i++;
        }
        my ($key,$val);
        while (($key,$val) = each(%q))
        {
            $q{$key} = $val->[0] unless $#$val;
        }
        $self->{q} = { %t,%q };
    }

    $self->{tpl_vars} = $defaults;

    return $self;
}

sub form_attrs
{
    my ($caller,$form) = @_;
    $caller->SUPER::form_attrs($form);
    $form->{GT} = qq[WIDTH="80%" CELLPADDING="5" CELLSPACING="0" BORDER="0"];
    $form->{VFL} = qq[WIDTH="40%" ALIGN="RIGHT"];
    return $form;
}

##at should somehow cache templates
##at Accept scalar references
sub output
{
    my ($self,$out,$tplf) = @_;
    $tplf = $ENV{CRUDDY_FAST_TEMPLATE_MAIN} || $DEFAULT_TPL_MAIN unless $tplf;

    my $tpl = new CGI::FastTemplate($ENV{CRUDDY_FAST_TEMPLATE_PATH} || $DEFAULT_TPL_PATH);
##at should check return value because an OS call was done
    $tpl->define(main => $tplf);
    $self->{tpl_vars}{BODY} = (ref($out) ? $$out : $out) if defined($out);
    $tpl->assign($self->{tpl_vars});
    $tpl->parse(CONTENT => 'main');
    my $gob = $tpl->fetch('CONTENT');

    $self->{apache}->no_cache(1) if $ENV{MOD_PERL};
    $self->{apache}->content_type('text/html') if $ENV{MOD_PERL};
    $self->{apache}->print($$gob) if $ENV{MOD_PERL};
    return 1;
}

1;
