package CatalystX::RoseIntegrator;

use strict;
use base qw/Catalyst::Controller Class::Accessor::Fast Class::Data::Inheritable/;
use File::Find;
use Config::Loader ();
use Catalyst::Utils;
use Module::Pluggable::Object;
use Data::Dumper;

our $VERSION = '0.02';

__PACKAGE__->mk_accessors(qw/_rinteg_setup _attr_params _plugin_locator/);
__PACKAGE__->mk_accessors(qw/form_name _form has_error/);
__PACKAGE__->mk_classdata($_) for qw/_forms _forms_created/;

sub new
{
    my $class = shift;
    my $self  = $class->NEXT::new(@_);
    $self->__setup();
    return $self;
}

sub __setup
{
    my $self   = shift;
    my $class  = ref $self;

    my $config = $self->config->{'CatalystX::RoseIntegrator'} || {};

    my $method = $config->{method_name} || 'rinteg';
    my $tmpl_type = $config->{template_type} || "TT";
    my $action = $config->{action} || "CatalystX::RoseIntegrator::Action::$tmpl_type";

    $self->_rinteg_setup({
	method_name => $method,
	stash_name  => $config->{stash_name} || 'rinteg',
	obj_name    => $config->{obj_name} || 'RINTEG',
	action      => $action,
	attr_name   => $config->{attr_name} || 'Form',
	source_type => $config->{source_type} || undef,
	template_type => $tmpl_type,
    });

    $self->_setup_forms($config) unless __PACKAGE__->_forms_created;
    __PACKAGE__->_forms_created(1);
}

sub _setup_forms
{
    my ($self, $config) = @_;
    # Load configured defaults from the user, and add in some
    # custom settings needed to meld RINTEG with Catalyst

    $self->_load_conf_data($config);
    __PACKAGE__->_forms({});

    my @paths   = qw( ::Controller ::C ::Model ::M ::View ::V );
    my $s_config  = $self->_app->config->{ setup_components };
    my $extra   = delete $s_config->{ search_extra } || [];
    
    push @paths, @$extra;
    my $locator = Module::Pluggable::Object->new(
						 search_path => [ map { s/^(?=::)/$self->_app/e; $_; } @paths ],
						 %$s_config
						 );

    $self->_plugin_locator([ $locator->plugins ]);

    foreach my $conf_dir (grep { /^conf_/ } keys %$config) {
	my $form_refs = $config->{$conf_dir}{conf}->();
	foreach my $conf (keys %$form_refs) {
	    $self->_create_rinteg($config, $form_refs, $conf);
	}
    }
}

sub _create_rinteg
{
    my ($self, $config, $form_refs, $conf) = @_;

    my $name_test  = $form_refs->{$conf}{name};
    my $name = !ref($name_test) ? $name_test : '';
    my $rdbos_test = $form_refs->{$conf}{rdbo};
    my $rdbos = (( ref($rdbos_test) && ref($rdbos_test) eq 'ARRAY') ||
		 (!ref($rdbos_test)))
	? $rdbos_test : '';

    if ($name || $rdbos) {
	$self->_do_create_rinteg($config, $form_refs->{$conf}, $name, $rdbos);
    } else {
	# Recursively inspect the tree
	$self->_create_rinteg($config, $form_refs->{$conf}, $_) for keys %{$form_refs->{$conf}};
    }
}

sub _do_create_rinteg
{
    my ($self, $config, $form_ref, $name, $rdbos) = @_;
    my $def_name  = '';
    my $fields_h  = {};
    my $fields_a  = [];
    my $use_rdbos = '';
    my $module;

    my $rdbos_a = ref($rdbos) ? $rdbos : [ $rdbos ]; # WARNING: Only *one* rdbo is sufficient for the moment

    foreach my $rdbo (@$rdbos_a) {
	next unless defined($rdbo);
	($module) = grep { /::$rdbo$/ } @{$self->_plugin_locator};
	warn "loading class $rdbo from module $module\n";
	&Catalyst::Utils::ensure_class_loaded($module);

	$def_name  .= $rdbo;
	$use_rdbos .= "use $module;";

	my $meta    = "$module"->meta;
	my $fks_a   = $meta->foreign_keys;
	
	foreach my $col ($meta->columns) {
	    my $field_h = {};
	    my $col_name = $col->name;

	    $field_h->{name} = $col_name;
	    $field_h->{type} = $col->type;
	    $field_h->{size} = $col->length if $field_h->{type} ne 'textarea' && $col->can('length') && $col->length;
	    
	    foreach my $fk (@$fks_a) {
		my $fk_class = $fk->class;
		if (my $fk_col = $fk->key_column($col_name)) {
		    my ($fk_module) = grep { /::$fk_class$/ } @{$self->_plugin_locator};
		    &Catalyst::Utils::ensure_class_loaded($fk_module);
		    $field_h->{name} = "$col_name:" . $fk_col->name;
		    $field_h->{type} = $fk_col->type;
		    $field_h->{size} = $fk_col->length if $fk_col->can('length') && $fk_col->length;
		    last;
		}
	    }
	    $fields_h->{$col_name} = $field_h;
	}
    }

    my @fields_order = ref($form_ref->{fields_order}) eq 'ARRAY' ? @{$form_ref->{fields_order}} : split(/\s*,\s*/, $form_ref->{fields_order});
    foreach my $field_name ( @fields_order ) {
	my $field_h = $form_ref->{fields}{$field_name};
	$fields_h->{$field_name}{$_} = $field_h->{$_} for keys %$field_h;
	$fields_h->{$field_name}{name} ||= $field_name;
	push @{ $fields_a }, $fields_h->{$field_name};
    }

    $name ||= $def_name;
    $name =~ s/Form$//;
    my $form_class = $name . 'Form';
    my $name_lc = lc $def_name;
    my @ordered_fields = ();

    __PACKAGE__->_forms->{$form_class} = $fields_a;

    eval "package $form_class;use base 'Rose::HTML::Form';$use_rdbos;";
    die $@ if $@;

    no strict 'refs';

    *{"$form_class\::init_with_$name_lc"} = sub {
	my ($cl_self, $object) = @_;

	foreach my $f_name (map { $_->name } $cl_self->ordered_fields) {
	    next if $f_name eq 'submit';
	    my ($col, $dummy, $fk_col) = $f_name =~ /([^:]*)(:(.*))?/;
	    if ($fk_col) {
		my ($col_wo_id) = $col =~ /^(.*)_id$/;
		$cl_self->field($f_name)->value($object->$col_wo_id->id);
	    } else {
		$cl_self->field($f_name)->value($object->$f_name);
	    }
	}
    };

    *{"$form_class\::${name_lc}_from_form"} = sub {
	my ($cl_self, $object) = @_;

	foreach my $f_name (map { $_->name } $cl_self->ordered_fields) {
	    next if $f_name eq 'submit';
	    my ($col, $dummy, $fk_col) = $f_name =~ /([^:]*)(:(.*))?/;
	    if ($fk_col) {
		$object->$col($cl_self->field($f_name)->input_value);
	    } else {
		$object->$f_name($cl_self->field($f_name)->input_value);
	    }
	}
    };

    *{"$form_class\::build_form"} = sub {
	my $cl_self  = shift;
	my $class    = ref($cl_self);	
	my $form_def = __PACKAGE__->_forms->{$class};

	foreach my $field_h (@$form_def) {
	    my $f_name = $field_h->{name};
	    $cl_self->{"_$f_name"}{$_} = delete $field_h->{$_} for qw/message regexp/;
	    warn "***** $f_name n'a pas de type\n" unless $field_h->{type};
	    $cl_self->add_field($f_name => $field_h);
	}
    };

    *{"$form_class\::ordered_fields"} = sub {
	my ($cl_self) = @_;
	return map { $cl_self->field($_) } @ordered_fields;
    };

    *{"$form_class\::add_field"} = sub {
	shift->Rose::HTML::Form::add_field(@_);
	push @ordered_fields, grep { !ref($_) } @_;
    };

    *{"$form_class\::add_fields"} = sub {
	shift->add_field(@_);
    };

    *{"$form_class\::init_auto_fields"} = sub {
	my ($cl_self, $c) = @_;

	foreach my $f_name ( grep { /:/ } map { $_->name } $cl_self->ordered_fields) {
	    my ($col, $fk_col) = $f_name =~ /(.*):(.*)/;
	    my ($mclass) = $col =~ /^(.*)_id$/;
	    $mclass = ucfirst($mclass) . "::Manager";
	    my @objects = sort { lc $a->$fk_col cmp lc $b->$fk_col } @{$c->model($mclass)->get_objects};
	    $self->form->field($f_name)->options( map { $_->id => $_->$fk_col } @objects);
	}
    };

    *{"$form_class\::relabelize"} = sub {
	my ($cl_self, $c) = @_;

	if ($c->can('localize')) {
	    my $class         = ref($cl_self);	
	    my $form_def      = __PACKAGE__->_forms->{$class};
	    
	    foreach my $field_h (@$form_def) {
		$cl_self->field($field_h->{name})->label($c->localize($field_h->{label}));
	    }
	}
    };

    *{"$form_class\::_validate"} = sub {
	my ($cl_self, $c, $f_name) = @_;
	my (@res, @msgs, @rets);
	my $field = $cl_self->field($f_name);
	my $f_is_valid = 1;
	
	my $res  = $cl_self->{"_$f_name"}{regexp};
	my $msgs = $cl_self->{"_$f_name"}{message};
	
	if (ref($res)) {
	    @res  = @$res;
	    @msgs = @$msgs;
	} else {
	    @res  = ($res);
	    @msgs = ($msgs);
	}

	for (my $lo = 0; $lo < @res; $lo++) {
	    my $re  =  $res[$lo];
	    my $msg = $msgs[$lo];
	    
	    next unless defined($re) && defined($msg);

	    if ($re =~ s/^-//) {
		if ($re eq 'auto') {
		    $f_is_valid = 0 unless $field->validate;
		} elsif ($re =~ /^same-as\s+(.*)$/i) {
		    my $in1 = $field->input_value;
		    my $in2 = $cl_self->field($1)->input_value;
		    $f_is_valid = 0 unless defined($in1) && defined($in2) && $in1 eq $in2;
		} else {
		    die "Invalid regexp";
		}
	    } else {
		my $in = $field->input_value;
		if (ref($field) =~ /textarea$/i) {
		    $f_is_valid = 0 unless defined($in) && $in =~ /$re/m;
		} else {
		    $f_is_valid = 0 unless defined($in) && $in =~ /$re/;
		}
	    }
	    if ($c->can('localize')) {
		push @rets, $c->localize($msg) unless $f_is_valid;
	    } else {
		push @rets, $msg unless $f_is_valid;
	    }
	}
	
	if (@rets) {
	    $cl_self->field($f_name)->error(join(', ', @rets));
	}

	return $f_is_valid;
    };
}

sub _load_conf_data
{
    my ( $self, $config ) = @_;
    my $count = 0;
    
    foreach my $dir ( @{$self->_form_path( $config )} ) {
	$config->{"conf_$count"} = {
	    dir => $dir,
	    conf => Config::Loader->new($dir),
	};
	$count++;
    }
}

sub _form_path
{
    my ($self, $config) = @_;

    my $rinteg_dir = [ File::Spec->catfile( $self->_app->config->{home}, 'root', 'forms' ) ];

    if (my $dir = $config->{form_path}) {
        $rinteg_dir = ref $dir ? $dir : [ split /\s*:\s*/, $dir ];
    }

    return $rinteg_dir;
}

sub rinteg
{
}

sub _rinteg {
    my $self   = shift;
    my $method = $self->_rinteg_setup->{method_name};
    $self->$method(@_);
}

sub create_action
{
    my $self = shift;

    my %args = @_;
    my $attr_name = $self->_rinteg_setup->{attr_name};

     if (exists $args{attributes}{$attr_name}) {
#         $args{_attr_params} = delete $args{attributes}{$attr_name};
         push @{ $args{attributes}{ActionClass} }, $self->_rinteg_setup->{action};
     }

    $self->SUPER::create_action(%args);
}

sub _form_init
{
    my ($self, $force) = @_;
    my $form = $self->_form;

    if ($force || !$form) {
	my $form_name = $self->form_name;
	$form = $self->_form("$form_name"->new);
    }

    return $form;
}

sub form
{
    my ($self) = @_;
    my $form = $self->_form;

    $form = $self->_form_init unless $form;

    return $form;
}

sub _process
{
    my ($self, $c) = @_;
    my $form       = $self->_form;
    my $form_name  = $self->form_name;
    my $has_error  = 0;

    foreach my $f_name (map { $_->name } $form->ordered_fields) {
	$has_error++ unless $form->_validate($c, $f_name);
    }

    $self->has_error($has_error);
}

1;

__END__

# Original Catalyst::Controller::FormBuilder code is Copyright (c) 2006 Juan Camacho <formbuilder@suspenda.com>. All Rights Reserved.
# CatalystX::RoseIntegrator adaptation Copyright (c) 2007 Alexandre (Midnite) Jousset <cpan@gtmp.org>. All Rights Reserved.

=head1 NAME

CatalystX::RoseIntegrator - Catalyst/Rose Base Controller

=head1 WORK IN PROGRESS

WARNING: This is beta software. It works for me, not necessarily for you.

This documentation may lack information and / or be wrong. But it is a good
start.

Feel free to report anything you would like to report ;-)

=head1 SYNOPSIS

    package MyApp::Controller::Books;
    use base 'CatalystX::RoseIntegrator';

    # optional config setup
    __PACKAGE__->config(
        'CatalystX::RoseIntegrator' = {
            template_type => 'TT',    # default is 'TT' (i.e. TT2), only TT supported for the moment
        }
    );

    # looks for books/edit.fb form configuration file, based on the presence of
    # the ":Form" attribute.
    sub edit : Local Form {
        my ( $self, $c, @args ) = @_;

        my $form = $self->form;

        # add email form field to fields already defined edit.fb
        $form->add_field( name => 'email', type => 'email' );

        if ( $form->was_submitted ) {
            if ( $self->has_error ) {
                $c->stash->{ERROR}          = "INVALID FORM";
            }
            else
	    {
                return $c->response->body("VALID FORM");
            }
        }
    }

    # explicitedly use books/edit.fb, otherwise books/view.fb is used
    sub view : Local Form('/books/edit') {
        my ( $self, $c ) = @_;
        $c->stash->{template} = "books/edit.tt" # TT2 template;
    }

=head1 DESCRIPTION

This base controller gives the power of Rose HTML/DB Objects to Catalyst
in a simple manner.

Rose::HTML/DB::Object(s)? usage within Catalyst is straightforward. Since Catalyst
handles page rendering, you don't call RHTMLO's methods, as you
would normally. Instead, you simply add a C<:Form> attribute to each method
that you want to associate with a form. This will give you access to a
RHTMLO::Form C<< $self->form >> object within that controller method:

    # An editing screen for books
    sub edit : Local Form {
        my ( $self, $c ) = @_;
        $self->form->method('post');   # set form method
    }

The out-of-the-box setup is to look for a form configuration file,
usually in L<Config::General> format but any format recognized by 
L<Config::Loader> should work, named for the current action url.
So, if you were serving C</books/edit>, this plugin would look for:

    root/forms/books/edit.conf

(The path is configurable) If no source file is found, an error is throwed.

Here is an example C<edit.yaml> file (borrowed and adapted from you know
where):

    # Form config file root/forms/books/edit.yaml
    name: books_edit
    method: post
    rdbo: Book
    fields_order: title, author, isbn, desc, submit
    fields:
        title:
            label: Book Title
            type:  text
            required: 1
            regexp: ^.{0,50}$
            message: Max 50 characters
            regexp: ^[\w\.\(\)\s-]*$
	    message: Forbidden character(s)
        author:
            label: Author's Name
            type:  text
            required: 1
            regexp: ^.{0,50}$
            message: Max 50 characters
            regexp: ^[\w\.\(\)\s-]*$
	    message: Forbidden character(s)
        isbn:
            label: ISBN#
            type:  text
            regexp: ^(\d{10}|\d{13})$
            message: Invalid ISBN number
            required: 1
        desc:
            label: Description
            type:  textarea
            cols:  80
            rows:  5
        submit:
            type: submit

Notice the 'rdbo' line, that specifies an optional RDBO class to
tie to. With this, you don't have to specify sizes for the fields
and you will be allowed to load and save content from / to  the form
directly from / to the DB.

To do that, use this:

    my $book = $c->model('Book')->new;
    $form->book_from_form($book);
    $book->save,

and

    my $book = $c->model('Book')->new(id => 15);
    $form->init_with_book($book);

Also notice that each validation regexp is associated with an error message.
In the regexp field, instead of a real regexp, you can write -auto to check
automatically the value with the type of the field (RHTMLO side). You can also
enter C<-same-as> I<field> to check for equality (ASCII sense) with another
field. This is good for password or email confirmations.

This will automatically create a complete form for you, using the
specified fields. Note that the C<root/forms> path is configurable;
this path is used by default to integrate with the C<TTSite> helper.

Within your controller, you can call any method that you would on a
normal C<RHTMLO> object on the C<< $self->form >> object.
To manipulate the field named C<desc>, simply call the C<field()>
method:

    # Change our desc field dynamically
    $self->form->field(desc,
        name     => 'desc',
        label    => 'Book Description',
        required => 1
    );

To populate field options for C<country>, you might use something like
this to iterate through the database:

    # not tested!
    $self->form->field(country,
        name    => 'country',
        options =>
          [ map { [ $_->id, $_->name ] } $c->model('Country::Manager')->get_countries ],
    );

The RHTMLO methodolody is to handle both rendering and validation
of the form. As such, the form will "loop back" onto the same controller
method. Within your controller, you would then use the standard RHTMLO
submit/validate check:

    if ( $self->form->was_submitted && !$self->has_error ) {
        $c->forward('/books/save');
    }

This would forward to C</books/save> if the form was submitted and
passed field validation. Otherwise, it would automatically re-render the
form with invalid fields highlighted, leaving the database unchanged.

To render the form in your tt2 template for example, you can use something
like this to get a standard form for all your site:

    <!-- root/src/myform.tt, included in other templates -->
    [% c.localize("An asterisk (<strong>*</strong>) indicates a mandatory field.") %]<br>
    [% RINTEG.start_xhtml %]

    [% FOREACH field IN RINTEG.ordered_fields %]
        [% field.xhtml_label %] [% IF field.required %] <strong>*</strong> [% END %]
        [% IF field.error %]
            <span class="error small">
                [% field.error %]
            </span>
        [% END %]
        <br>
        [% field.xhtml_field %]
        <br><br>
    [% END %]

    [% RINTEG.end_xhtml %]

=head1 SEE ALSO

L<Catalyst::Controller::FormBuilder> on which it is originally derived
L<Catalyst::Manual>, L<Catalyst::Request>, L<Catalyst::Response>
L<Rose::HTML::Objects>, L<Rose::DB::Object>

=head1 AUTHOR

Copyright (c) 2007 Alexandre Jousset <cpan@gtmp.org>. All Rights Reserved.

Thanks to Juan Camacho for inspiration (Catalyst::Controller::FormBuilder)

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
