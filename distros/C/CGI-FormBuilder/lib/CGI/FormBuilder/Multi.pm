
###########################################################################
# Copyright (c) Nate Wiger http://nateware.com. All Rights Reserved.
# Please visit http://formbuilder.org for tutorials, support, and examples.
###########################################################################

package CGI::FormBuilder::Multi;

=head1 NAME

CGI::FormBuilder::Multi - Create multi-page FormBuilder forms 

=head1 SYNOPSIS

    use CGI::FormBuilder::Multi;
    use CGI::Session;   # or something similar

    # Top-level "meta-form"
    my $multi = CGI::FormBuilder::Multi->new(

        # form 1 options
        { fields   => [qw(name email daytime_phone evening_phone)],
          title    => 'Basic Info',
          template => 'page1.tmpl',
          validate => { name => 'NAME', email => 'EMAIL' },
          required => [qw(name email daytime_phone)],
        },

        # form 2 options
        { fields   => [qw(billing_name billing_card billing_exp
                          billing_address billing_city billing_state
                          billing_zip billing_phone)],
          title    => 'Billing',
          template => 'page2.tmpl',
          required => 'ALL',
        },

        # form 3 options
        { fields   => [qw(same_as_billing shipping_address
                          shipping_city shipping_state shipping_zip)],
          title    => 'Shipping',
          template => 'page3.tmpl',
          required => 'ALL',
        },

        # a couple options specific to this module
        navbar => 1,

        # remaining options (not in hashrefs) apply to all forms
        header => 1,
        method => 'POST',
        submit => 'Continue',
        values => $dbi_hashref_query,
    );

    # Get current page's form
    my $form = $multi->form;

    if ($form->submitted && $form->validate) {

        # Retrieve session id
        my $sid = $form->sessionid;

        # Initialize session
        my $session = CGI::Session->new("driver:File", $sid, {Directory=>'/tmp'});

        # Automatically store updated data in session
        $session->save_param($form);

        # last page?
        if ($multi->page == $multi->pages) {
            print $form->confirm;
            exit;
        }

        # Still here, goto next page
        $multi->page++;

        # And re-get form (no "my" on $form!)
        $form = $multi->form;

        # Make sure it has the right sessionid
        $form->sessionid($session->id);

        # on page 3 we have special field handling
        if ($multi->page == 3) {
            $form->field(name    => 'same_as_billing',
                         type    => 'checkbox',
                         options => 'Yes',
                         jsclick => 'this.form.submit()');
        }
    }

    # Fall through and print next page's form
    print $form->render;

=cut

use strict;
use warnings;
no  warnings 'uninitialized';

use CGI::FormBuilder;
use CGI::FormBuilder::Util;

our $VERSION = '3.20';

our %DEFAULT = (
    pagename => '_page',
    navbar   => 0,
);

sub new {
    my $mod = shift;
    my $class = ref($mod) || $mod;

    # Arg parsing is a little more complex than FormBuilder proper,
    # since we keep going thru our options until we don't see hashrefs
    my @forms = ();
    while (ref $_[0]) {
        push @forms, shift;
    }

    # Remaining options are form opts
    my %opt  = arghash(@_);

    # If no forms, and specified number of pages, use that instead
    if ($opt{pages}) {
        puke "Can't specify pages and form hashrefs" if @forms;
        my $p = 0;
        push @forms, {} while $p++ < $opt{pages};
    }
    puke "Must specify at least one form or 'pages' option for ::Multi" unless @forms;

    # Check for CGI params
    # This is duplicated code straight out of FormBuilder.pm,
    # but it's needed here as well so we can get our _page
    unless ($opt{params} && ref $opt{params} ne 'HASH') {
        require CGI;
        $CGI::USE_PARAM_SEMICOLONS = 0;     # fuck ; in urls
        $opt{params} = CGI->new($opt{params});
    }               

    # Options for me
    my %me;
    while (my($k,$v) = each %DEFAULT) {
        $me{$k} = exists $opt{$k} ? delete $opt{$k} : $v;
    }
    $me{forms} = \@forms;

    # Plop in our defaults per-form unless it's an object
    @forms = map { ref $_ eq 'HASH' ? { %opt, %$_ } : $_ } @forms;

    # Top-level multi
    my $self = bless \%me, $class;

    # Copy CGI object into self, and get page
    $self->{params} = $opt{params};
    $self->{keepextras} = $opt{keepextras};
    $self->{page}   = $self->{params}->param($self->{pagename}) || 1;

    return $self;
}

# return an lvalue to allow $multi->page++ and $multi->page--;
sub page : lvalue {
    my $self = shift;
    $self->{page} = shift if @_;    # rvalue
    $self->{page};                  # lvalue
}

*forms = \&pages;
sub pages {
    my $self = shift;
    puke "No arguments allowed to \$multi->pages or \$multi->forms" if @_;
    return @{$self->{forms}};
}

# return the form from this page, as a new object
sub form {
    my $self = shift;
    puke "No arguments allowed to \$multi->form" if @_;
    my $page = $self->page;
    my $idx  = $page - 1;

    return $self->{_cache}{forms}[$idx] if $self->{_cache}{forms}[$idx];
    puke "Invalid page $page, no form present"
        unless my $form = $self->{forms}[$idx];

    if (ref $form eq 'CGI::FormBuilder') {
        # already constructed
    } else {
        $form = CGI::FormBuilder->new(%$form);
    }

    # hooks
    $form->page($self->page);
    $form->text(scalar $self->navbar) if $self->{navbar}; # cheat

    # create new $form and cache for re-get
    $self->{_cache}{forms}[$idx] = $form;
}

# allow jumps between pages
sub navbar {
    my $self = shift;
    $self->{navbar} = shift if @_;
    my $base = basename; 
    my $pnam = $self->{pagename};
    return '' unless $self->pages > 1;

    # Look for extra params to keep
    # Algorithm here is a bit different
    my @keep;
    if ($self->{keepextras}) {
        unless (ref $self->{keepextras}) {
            $self->{keepextras} = [ $self->{params}->param ];
        }
        for my $k (@{$self->{keepextras}}) {
            next if $k eq $pnam;
            for my $v ($self->{params}->param($k)) {
                push @keep, { name => $k, value => $v };
            }
        }
    }

    my @html = ();
    for (my $p=1; $p <= $self->pages; $p++) {
        my $cl = $self->page == $p ? 'fb_multi_page' : 'fb_multi_link';
         
        # this looks like gibberish
        my $purl = basename . '?' . join '&',
            map { "$_->{name}=$_->{value}" } @keep,
                     { name => $pnam, value => $p };
 
        push @html, htmltag('a', href => $purl, class => $cl)
                    . ($self->{forms}[$p-1]{title} || "Page $p") . '</a>';
    }

    return wantarray ? @html : '<p>'. join(' | ', @html) . '<p>';
}

1;
__END__

=head1 DESCRIPTION

This module works with C<CGI::FormBuilder> to create multi-page forms.
Each form is specified using the same options you would pass directly
into B<FormBuilder>. See L<CGI::FormBuilder> for a list of these options.

The multi-page "meta-form" is a composite of the individual forms you
specify, tied together via the special C<_page> CGI param. The current
form is available via the C<form()> method, and the current page is
available via C<page()>. It's up to you to navigate appropriately:

    my $multi = CGI::FormBuilder::Multi->new(...);

    # current form
    my $form  = $multi->form;

    $multi->page++;         # page forward
    $multi->page--;         # and back
    $multi->page = $multi->pages;   # goto last page

    # current form
    $form = $multi->form;

To make things are fluid as possible, you should title each of your
forms, even if you're using a template. This will allow C<::Multi>
to create cross-links by-name instead of just "Page 2".

=head1 METHODS

The following methods are provided:

=head2 new(\%form1, \%form2, opt => val)

This creates a new C<CGI::FormBuilder::Multi> object. Forms are
specified as hashrefs of options, in sequential order, similar to
how fields are specified. The order the forms are in is the order
that the pages will cycle through.

In addition to a hashref, forms can be directly specified as a
C<$form> object that has already been created. For existing objects,
the below does not apply.

When the first non-ref argument is seen, then all remaining args
are taken as common options that apply to all forms. In this way,
you can specify global settings for things like C<method> or
C<header> (which will likely be the same), and then override
individual settings like C<fields> and C<validate> on a per-form
basis.

If you do not wish to specify any options for your forms, you
can instead just specify the C<pages> option, for example:

    my $multi = CGI::FormBuilder::Multi->new(pages => 3);

With this approach, you will have to dynamically assemble each
page as you come to them. The mailing list can help.

The L</"SYNOPSIS"> above is very representative of typical usage.

=head2 form()

This returns the current page's form, as an object created
directly by C<< CGI::FormBuilder->new >>. All valid B<FormBuilder>
methods and options work on the form. To change which form is
returned, us C<page()>.

=head2 page($num)

This sets and returns the current page. It can accept a page number
either as an argument, or directly as an assignment:

    $multi->page(1);    # page 1
    $multi->page = 1;   # same thing

    $multi->page++;     # next page
    $multi->page--;     # back one

    if ($multi->page == $multi->pages) {
        # last page
    }

Hint: Usually, you should only change pages once you have validated
the current page's form appropriately.

=head2 pages()

This returns the total number of pages. Actually, what it returns
is an array of all forms (and hence it has the alias C<forms()>),
which just so happens to become the length in a scalar context,
just like anywhere else in Perl.

=head2 navbar($onoff)

This returns a navigation bar that allows the user to jump between
pages of the form. This is useful if you want to let a person fill
out different pages out of order. In most cases, you do I<not>
want this, so it's off by default.

To use it, the best way is setting C<< navbar => 1 >> in C<new()>.
However, you can also get it yourself to render your own HTML:

    my $html = $multi->navbar;      # scalar HTML
    my @link = $multi->navbar;      # array of links

This is useful in something like this:

    my $nav = $multi->navbar;
    $form = $multi->form;
    $form->tmpl_param(navbar => $navbar);

The navbar will have two style classes: C<fb_multi_page> for the
current page's link, and C<fb_multi_link> for the others.

=head1 SEE ALSO

L<CGI::FormBuilder>

=head1 REVISION

$Id: Multi.pm 100 2007-03-02 18:13:13Z nwiger $

=head1 AUTHOR

Copyright (c) L<Nate Wiger|http://nateware.com>. All Rights Reserved.

This module is free software; you may copy this under the terms of
the GNU General Public License, or the Artistic License, copies of
which should have accompanied your Perl kit.

=cut

