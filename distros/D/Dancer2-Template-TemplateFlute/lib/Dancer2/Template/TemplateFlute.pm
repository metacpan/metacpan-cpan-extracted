package Dancer2::Template::TemplateFlute;

=head1 NAME

Dancer2::Template::TemplateFlute - Template::Flute wrapper for Dancer2

=head1 VERSION

Version 0.203

=cut

our $VERSION = '0.203';

use Carp qw/croak/;
use Dancer2::Core::Types;
use Module::Runtime qw/use_module/;
use Scalar::Util qw/blessed/;
use Template::Flute;
use Template::Flute::Iterator;
use Template::Flute::Utils;
use Template::Flute::I18N;
use Try::Tiny;

use Moo;
with 'Dancer2::Core::Role::Template';
use namespace::clean;

has autodetect_disable => (
    is      => 'ro',
    isa     => ArrayRef,
    lazy    => 1,
    default => sub {
        my $self = shift;
        # do we need to add anything to default list?
        my @autodetect_disable = ();
        if ( my $autodetect = $self->config->{autodetect} ) {
            push @autodetect_disable, @{ $autodetect->{disable} };
        }
        return \@autodetect_disable;
    },
);

has check_dangling => (
    is      => 'ro',
    isa     => Bool,
    lazy    => 1,
    default => sub { shift->config->{check_dangling} },
);

has disable_check_dangling => (
    is      => 'ro',
    isa     => Bool,
    lazy    => 1,
    default => sub { shift->config->{disable_check_dangling} },
);

has '+default_tmpl_ext' => (
    default => sub { shift->config->{extension} || 'html' },
);

has filters => (
    is      => 'ro',
    isa     => HashRef,
    lazy    => 1,
    default => sub { shift->config->{filters} || +{} },
);

has iterators => (
    is      => 'rw',
    isa     => HashRef,
    lazy    => 1,
    default => sub { shift->config->{iterators} || +{} },
);

has i18n_obj => (
    is  => 'lazy',
    isa => InstanceOf['Template::Flute::I18N'],
);

sub _build_i18n_obj {
    my $self = shift;
    my $conf = $self->config;
    my $localize;
    if ( $conf and exists $conf->{i18n} and exists $conf->{i18n}->{class} ) {
        my $class = $conf->{i18n}->{class};
        my %args;
        if ( $conf->{i18n}->{options} ) {

            # do a shallow copy and pass that
            %args = %{ $conf->{i18n}->{options} };
        }
        my $obj = try {
            use_module($class)->new(%args);
        }
        catch {
            croak "Failed to import class $class: $_";
        };
        my $method = $conf->{i18n}->{method} || 'localize';

        # store the closure in the object to avoid loading it up each time
        $localize = sub {
            my $to_translate = shift;
            return $obj->$method($to_translate);
        };
    }

    # provide a common interface with Template::Flute::I18N
    return Template::Flute::I18N->new($localize);
}

sub render ($$$) {
    my ( $self, $template, $tokens ) = @_;
    my ( %args, $flute, $html, $name, %parms, %template_iterators,
        %iterators, $class );

    %args = (
        template_file  => $template,
        scopes         => 1,
        auto_iterators => 1,
        values         => $tokens,
        filters        => $self->filters,
        autodetect     => { disable => $self->autodetect_disable },
        #autodetect     => { disable => [qw/Dancer2::Session::Abstract/] },
    );

    # determine whether we need to pass an adjust URI to Template::Flute
    if ( my $request = $tokens->{request} ) {
        $args{uri} = $request->base->path if $request->base->path ne '/';
    }

    if ( my $i18n = $self->i18n_obj ) {
        $args{i18n} = $i18n;
    }

    if ( my $email_cids = $tokens->{email_cids} ) {
        $args{email_cids} = $email_cids;

        # use the 'cids' tokens only if email_cids is defined
        if ( my $cid_options = $tokens->{cids} ) {
            $args{cids} = {%$cid_options};
        }
    }

    $flute = Template::Flute->new(%args);

    # process HTML template to determine iterators used by template
    $flute->process_template();

    # instantiate iterators where object isn't yet available
    if ( %template_iterators = $flute->template()->iterators ) {
        my $selector;

        for my $name ( keys %template_iterators ) {
            if ( my $value = $self->iterators->{$name} ) {
                %parms = %$value;

                $class = "Template::Flute::Iterator::$parms{class}";

                if ( $parms{file} ) {
                    $parms{file} =
                      Template::Flute::Utils::derive_filename( $template,
                        $parms{file}, 1 );
                }

                if ( $selector = delete $parms{selector} ) {
                    if ( $selector eq '*' ) {
                        $parms{selector} = '*';
                    }
                    elsif ( $tokens->{$selector} ) {
                        $parms{selector} =
                          { $selector => $tokens->{$selector} };
                    }
                }

                eval "require $class";
                if ($@) {
                    croak "Failed to load class $class for iterator $name: $@\n";
                }

                eval { $iterators{$name} = $class->new(%parms); };

                if ($@) {
                    croak "Failed to instantiate class $class for iterator $name: $@\n";
                }

                $flute->specification->set_iterator( $name, $iterators{$name} );
            }
        }
    }

    # check for forms
    if ( my @forms = $flute->template->forms() ) {
        if ( $tokens->{form} ) {
            $self->_tf_manage_forms( $flute, $tokens, @forms );
        }
        else {
            $self->log_cb->( 'debug',
                'Missing form parameters for forms '
                  . join( ", ", sort map { $_->name } @forms ) );
        }
    }
    elsif ( $tokens->{form} ) {
        my $form_name =
          blessed( $tokens->{form} ) ? $tokens->{form}->name : $tokens->{form};

        $self->log_cb->( 'debug',
                "Form $form_name passed, "
              . "but no forms found in the template $template." );
    }

    $html = $flute->process();

    if (
        $self->check_dangling
        or ( $tokens->{settings}->{environment} eq 'development'
            && !$self->disable_check_dangling )
      )
    {

        if ( my @warnings = $flute->specification->dangling ) {
            foreach my $warn (@warnings) {
                $self->log_cb->(
                    'debug',
                    'Found dangling element '
                      . $warn->{type} . ' '
                      . $warn->{name} . ' (',
                    $warn->{dump},
                    ')'
                );
            }
        }
    }
    return $html;
}

sub _tf_manage_forms {
    my ( $self, $flute, $tokens, @forms ) = @_;

    # simple case: only one form passed and one in the flute
    if ( ref( $tokens->{form} ) ne 'ARRAY' ) {
        my $form_name = $tokens->{form}->name;
        if ( @forms == 1 ) {
            my $form = shift @forms;
            if (   $form_name eq 'main'
                or $form_name eq $form->name )
            {
                $self->_tf_fill_forms( $flute, $tokens->{form}, $form,
                    $tokens );
            }
        }
        else {
            my $found = 0;
            foreach my $form (@forms) {
                if ( $form_name eq $form->name ) {
                    $self->_tf_fill_forms( $flute, $tokens->{form}, $form,
                        $tokens );
                    $found++;
                }
            }
            if ( $found != 1 ) {
                $self->log_cb->(
                    'error', "Multiple form are not being managed correctly, found $found corresponding forms, but we expected just one!"
                );
            }
        }
    }
    else {
        foreach my $passed_form ( @{ $tokens->{form} } ) {
            foreach my $form (@forms) {
                if ( $passed_form->name eq $form->name ) {
                    $self->_tf_fill_forms( $flute, $passed_form, $form,
                        $tokens );
                }
            }
        }
    }
}

sub _tf_fill_forms {
    my ( $self, $flute, $passed_form, $form, $tokens ) = @_;

    # arguments:
    # $flute is the template object.

    # $passed_form is the Dancer::Plugin::Form object we got from the
    # tokens, which is $tokens->{form} when we have just a single one.

    # $form is the form object we got from the template itself, with
    # $flute->template->forms

    # $tokens is the hashref passed to the template. We need it for the
    # iterators.

    my ( $iter, $action );
    for my $name ( $form->iterators ) {
        if ( ref( $tokens->{$name} ) eq 'ARRAY' ) {
            $iter = Template::Flute::Iterator->new( $tokens->{$name} );
            $flute->specification->set_iterator( $name, $iter );
        }
    }
    if ( $action = $passed_form->action() ) {
        $form->set_action($action);
    }
    $passed_form->set_fields( [ map { $_->{name} } @{ $form->fields() } ] );
    $form->fill( $passed_form->values );

    $passed_form->to_session;
}

=head1 DESCRIPTION

This class is an interface between Dancer2's template engine abstraction layer
and the L<Template::Flute> module.

In order to use this engine, use the template setting:

    template: template_flute

The default template extension is ".html".

=head2 LAYOUT

Each layout needs a specification file and a template file. To embed
the content of your current view into the layout, put the following
into your specification file, e.g. F<views/layouts/main.xml>:

    <specification>
    <value name="content" id="content" op="hook"/>
    </specification>

This replaces the contents of the following block in your HTML
template, e.g. F<views/layouts/main.html>:

    <div id="content">
    Your content
    </div>

=head2 ITERATORS

Iterators can be specified explicitly in the configuration file as below.

  engines:
    template:
      template_flute:
        iterators:
          fruits:
            class: JSON
            file: fruits.json

=head2 FILTER OPTIONS

Filter options and classes can be specified in the configuration file as below.

  engines:
    template:
      template_flute:
        filters:
          currency:
            options:
              int_curr_symbol: "$"
          image:
            class: "Flowers::Filters::Image"

=head2 ADJUSTING URIS

We automatically adjust links in the templates if the value of
C<request->path> is different from C<request->path_info>.

=head2 EMBEDDING IMAGES IN EMAILS

If you pass a value named C<email_cids>, which should be an empty hash
reference, all the images C<src> attributes will be rewritten using
the CIDs, and the reference will be populated with an hashref, as
documented in L<Template::Flute>

Further options for the CIDs should be passed in an optional value
named C<cids>. See L<Template::Flute> for them.


=head2 DISABLE OBJECT AUTODETECTION

Sometimes you want to pass values to a template which are objects, but
don't have an accessor, so they should be treated like hashrefs instead.

You can specify classes with the following syntax:

  engines:
    template:
      template_flute:
        autodetect:
          disable:
            - My::Class1
            - My::Class2


The class matching is checked by L<Template::Flute> with C<isa>, so
any parent class would do.

=head2 LOCALIZATION

Templates can be localized using the Template::Flute::I18N module. You
can define a class that provides a method which takes as first (and
only argument) the string to translate, and returns the translated
one. You have to provide the class and the method. If the class is not
provided, no localization is done. If no method is specified,
'localize' will be used. The app will crash if the class doesn't
provide such method.

B<Be sure to return the argument verbatim if the module is not able to
translate the string>.

Example configuration, assuming the class C<MyApp::Lexicon> provides a
C<try_to_translate> method.

  engines:
    template:
      template_flute:
        i18n:
          class: MyApp::Lexicon
          method: try_to_translate


A class could be something like this:

  package MyTestApp::Lexicon;
  use Dancer2;

  sub new {
      my $class = shift;
      debug "Loading up $class";
      my $self = {
                  dictionary => {
                                 en => {
                                        'TRY' => 'Try',
                                       },
                                 it => {
                                        'TRY' => 'Prova',
                                       },
                                }
                 };
      bless $self, $class;
  }

  sub dictionary {
      return shift->{dictionary};
  }

  sub try_to_translate {
      my ($self, $string) = @_;
      my $lang = session('lang') || var('lang');
      return $string unless $lang;
      return $string unless $self->dictionary->{$lang};
      my $tr = $self->dictionary->{$lang}->{$string};
      defined $tr ? return $tr : return $string;
  }

  1;

Optionally, you can pass the options to instantiate the class in the
configuration. Like this:

  engines:
    template:
      template_flute:
        i18n:
          class: MyApp::Lexicon
          method: localize
          options:
            append: 'X'
            prepend: 'Y'
            lexicon: 'path/to/po/files'

This will call

 MyApp::Lexicon->new(append => 'X', prepend => 'Y', lexicon => 'path/to/po/files');

when the engine is initialized, and will call the C<localize> method
on it to get the translations.

=head2 DEBUG TOOLS

If you set C<check_dangling> in the engine stanza, the specification
will run a check (using the L<Template::Flute::Specification>'s
C<dangling> method) against the template to see if you have elements
of the specifications which are not bound to any HTML elements.

In this case a debug message is issued (so keep in mind that with
higher logging level you are not going to see it).

Example configuration:

  engines:
    template:
      template_flute:
        check_dangling: 1

When the environment is set to C<development> this feature is turned
on by default. You can silence the logs by setting:

  engines:
    template:
      template_flute:
        disable_check_dangling: 1

=head2 FORMS

Dancers::Template::TemplateFlute has a form plugin
L<Dancer2::Plugin::TemplateFlute> which must be installed in order to use
L<Template::Flute> forms.

The token C<form> is reserved for forms. It can be a single
L<Dancer2::Plugin::TemplateFlute> form object or an arrayref of
L<Dancer2::Plugin::TemplateFlute> form objects.

=head3 Typical usage for a single form.

=head4 XML Specification

  <specification>
  <form name="registration" link="name">
  <field name="email"/>
  <field name="password"/>
  <field name="verify"/>
  </form>
  </specification>

=head4 HTML

  <form class="frm-default" name="registration" action="/register" method="POST">
	<fieldset>
	  <div class="reg-info">Info</div>
	  <ul>
		<li>
		  <label>Email</label>
		  <input type="text" name="email"/>
		</li>
		<li>
		  <label>Password</label>
		  <input type="text" name="password"/>
		</li>
		<li>
		  <label>Confirm password</label>
		  <input type="text" name="verify" />
		</li>
		<li>
		  <input type="submit" value="Register" class="btn-submit" />
		</li>
	  </ul>
	</fieldset>
  </form>

=head4 Code

  any [qw/get post/] => '/register' => sub {
      my $form = request->is_post
          ? form('registration', source => 'body')
          : form('registration', source => 'session' );
      my %values = %{$form->values};
      # VALIDATE, filter, etc. the values
      template register => {form => $form };
  };

=head3 Usage example for multiple forms

=head4 Specification

  <specification>
  <form name="registrationtest" link="name">
  <field name="emailtest"/>
  <field name="passwordtest"/>
  <field name="verifytest"/>
  </form>
  <form name="logintest" link="name">
  <field name="emailtest_2"/>
  <field name="passwordtest_2"/>
  </form>
  </specification>

=head4 HTML

  <h1>Register</h1>
  <form class="frm-default" name="registrationtest" action="/multiple" method="POST">
	<fieldset>
	  <div class="reg-info">Info</div>
	  <ul>
		<li>
		  <label>Email</label>
		  <input type="text" name="emailtest"/>
		</li>
		<li>
		  <label>Password</label>
		  <input type="text" name="passwordtest"/>
		</li>
		<li>
		  <label>Confirm password</label>
		  <input type="text" name="verifytest" />
		</li>
		<li>
		  <input type="submit" name="register" value="Register" class="btn-submit" />
		</li>
	  </ul>
	</fieldset>
  </form>
  <h1>Login</h1>
  <form class="frm-default" name="logintest" action="/multiple" method="POST">
	<fieldset>
	  <div class="reg-info">Info</div>
	  <ul>
		<li>
		  <label>Email</label>
		  <input type="text" name="emailtest_2"/>
		</li>
		<li>
		  <label>Password</label>
		  <input type="text" name="passwordtest_2"/>
		</li>
		<li>
		  <input type="submit" name="login" value="Login" class="btn-submit" />
		</li>
	  </ul>
	</fieldset>
  </form>


=head4 Code

  any [qw/get post/] => '/multiple' => sub {
      my ( $login_form, $registration_form );
      debug to_dumper({params});

      if (params->{login}) {
          $login_form = form('logintest', source => 'parameters');
          my %vals = %{$login->values};
          # VALIDATE %vals here
      }
      else {
          # pick from session
          $login_form = form('logintest', source => 'session');
      }

      if (params->{register}) {
          $registration_form = form('registrationtest', source => 'parameters');
          my %vals = %{$registration->values};
          # VALIDATE %vals here
      }
      else {
          # pick from session
          $registration_form = form('registrationtest', source => 'session');
      }
      template multiple => { form => [ $login_form, $registration_form ] };
  };

=head1 METHODS

=head2 default_tmpl_ext

Returns default template extension.

=head2 render TEMPLATE TOKENS

Renders template TEMPLATE with values from TOKENS.

=head1 SEE ALSO

L<Dancer2>, L<Template::Flute>

=head1 AUTHOR

Author of the original Dancer module:

Stefan Hornburg (Racke), C<< <racke at linuxia.de> >>

Conversion to Dancer2:

Peter Mottram (SysPete), C<< <peter@sysnix.com> >>

Author of the original version of this Dancer2 module:

William Carr (mrmaloof), C<< <bill at bottlenose-wine.com> >>

=head1 BUGS

Please report any bugs or feature requests via the GitHub issue tracker at:
L<https://github.com/interchange/Dancer2-Template-TemplateFlute/issues>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer2::Template::TemplateFlute

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dancer2-Template-TemplateFlute>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dancer2-Template-TemplateFlute>

=item * meta::cpan

L<https://metacpan.org/pod/Dancer2::Template::TemplateFlute>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2011-2016 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
