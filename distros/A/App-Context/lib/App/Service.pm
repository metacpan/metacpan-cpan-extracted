
#############################################################################
## $Id: Service.pm 13305 2009-09-11 13:50:28Z spadkins $
#############################################################################

package App::Service;
$VERSION = (q$Revision: 13305 $ =~ /(\d[\d\.]*)/)[0];  # VERSION numbers generated by svn

use strict;

use App;

=head1 NAME

App::Service - Provides core methods for App-Context Services

=head1 SYNOPSIS

    use App::Service;

    # never really used, because this is a base class
    %named = (
        # named args would go here
    );
    $service = App::Service->new(%named);

=head1 DESCRIPTION

The App::Service class is a base class for all App-Context services.

    * Throws: App::Exception
    * Since:  0.01

=cut

#############################################################################
# CONSTRUCTOR METHODS
#############################################################################

=head1 Constructor Methods:

=cut

#############################################################################
# Method: new()
#############################################################################

=head2 new()

This constructor is used to create all objects which are App-Context services.
Customized behavior for a particular service is achieved by overriding
the _init() method.

    * Signature: $service = App::Service->new(%named)
    * Return:    $service       App::Service
    * Throws:    App::Exception
    * Since:     0.01

    Sample Usage: (never used because this is a base class, but the
    constructors of all services follow these rules)
    
    * If the number of arguments is odd, the first arg is the service name
      (otherwise, "default" is assumed)
    * If there are remaining arguments, they are variable/value pairs
    * If there are no arguments at all, the "default" name is assumed
    * If a "name" was supplied using any of these methods,
      the master config is consulted to find the config for this
      particular service instance (service_type/name).

    $service = App::Service->new();        # assumes "default" name
    $service = App::Service->new("srv1");  # instantiate named service
    $service = App::Service->new(          # "default" with named args
        arg1 => 'value1',
        arg2 => 'value2',
    );

=cut

sub new {
    &App::sub_entry if ($App::trace);
    my $this = shift;
    my $class = ref($this) || $this;
    my ($self, $context, $type);

    $context = App->context();
    $type = $class->service_type();
    if ($#_ % 2 == 0) {  # odd number of args
        $self = $context->service($type, @_, "class", $class);
    }
    else {  # even number of args (
        $self = $context->service($type, "default", @_, "class", $class);
    }
    &App::sub_exit($self) if ($App::trace);
    return $self;
}

#############################################################################
# Method: service_type()
#############################################################################

=head2 service_type()

Returns the service type (i.e. CallDispatcher, Repository, SessionObject, etc.).

    * Signature: $service_type = App::Service->service_type();
    * Param:     void
    * Return:    $service_type  string
    * Since:     0.01

    $service_type = $service->service_type();

=cut

sub service_type () { 'Service'; }

#############################################################################
# Method: content()
#############################################################################

=head2 content()

    * Signature: $content = $self->content();
    * Param:     void
    * Return:    $content   any
    * Throws:    App::Exception
    * Since:     0.01

    $content = $so->content();
    if (ref($content)) {
        App::Reference->print($content);
        print "\n";
    }
    else {
        print $content, "\n";
    }

=cut

sub content {
    &App::sub_entry if ($App::trace);
    my $self = shift;
    my $content = $self->internals();
    &App::sub_exit($content) if ($App::trace);
    return($content);
}

#############################################################################
# content_type()
#############################################################################

=head2 content_type()

    * Signature: $content_type = $service->content_type();
    * Param:     void
    * Return:    $content_type   string
    * Throws:    App::Exception
    * Since:     0.01

    Sample Usage: 

    $content_type = $service->content_type();

=cut

sub content_type {
    &App::sub_entry if ($App::trace);
    my $content_type = 'text/plain';
    &App::sub_exit($content_type) if ($App::trace);
    return($content_type);
}

#############################################################################
# content_description()
#############################################################################

=head2 content_description()

    * Signature: $content_description = $service->content_description();
    * Param:     void
    * Return:    $content_description   string
    * Throws:    App::Exception
    * Since:     0.01

Provide a description of the content which is useful for diagnostic purposes
(such as for the timing log implemented in App::Context::HTTP).

This method can be overridden by an application-specific service such as a
web application user interface widget to provide more useful information
in the description.

    Sample Usage: 

    $content_description = $service->content_description();

=cut

sub content_description {
    &App::sub_entry if ($App::trace);
    my ($self) = @_;
    my $class = ref($self);
    my $content_description = "$class($self->{name})";
    &App::sub_exit($content_description) if ($App::trace);
    return($content_description);
}

#############################################################################
# Method: internals()
#############################################################################

=head2 internals()

    * Signature: $guts = $self->internals();
    * Param:     void
    * Return:    $guts     {}
    * Throws:    App::Exception
    * Since:     0.01

    $guts = $so->internals();
    App::Reference->print($guts);
    print App::Reference->dump($guts), "\n";

Copy the internals of the current SessionObject to a new hash and return
a reference to that hash for debugging purposes.  The resulting hash
reference may be printed using Data::Dumper (or App::Reference).
The refe

=cut

sub internals {
    &App::sub_entry if ($App::trace);
    my ($self) = @_;
    my %copy = %$self;
    delete $copy{context};
    delete $copy{dict};
    &App::sub_exit(\%copy) if ($App::trace);
    return \%copy;
}

#############################################################################
# dump()
#############################################################################

=head2 dump()

    * Signature: $perl = $service->dump();
    * Param:     void
    * Return:    $perl      text
    * Throws:    App::Exception
    * Since:     0.01

    Sample Usage: 

    $service = $context->repository();
    print $service->dump(), "\n";

=cut

use Data::Dumper;

sub dump {
    my ($self, $ref) = @_;
    my ($copy, $data, $name);
    if ($ref) {
        if (!ref($ref)) {
            $data = $ref;
            $name = "scalar";
        }
        elsif (ref($ref) eq "ARRAY") {
            $data = [];
            my ($r);
            foreach my $d (@$ref) {
                $r = ref($d);
                if (!$r || $r eq "ARRAY" || $r eq "SCALAR") {
                    push(@$data, $d);
                }
                elsif (!$d->{context} && !$d->{_repository}) {
                    push(@$data, $d);
                }
                else {
                    $copy = { %$d };
                    $copy->{context} = "<removed>" if ($copy->{context});         # don't dump the reference to the context itself (Services)
                    $copy->{_repository} = "<removed>" if ($copy->{_repository}); # don't dump the reference to the repository (RepositoryObjects)
                    push(@$data, $copy);
                }
            }
            $data = [ $data ];
            $name = "array";
        }
        else {
            $copy = { %$ref };
            $copy->{context} = "<removed>" if ($copy->{context});         # don't dump the reference to the context itself (Services)
            $copy->{_repository} = "<removed>" if ($copy->{_repository}); # don't dump the reference to the repository (RepositoryObjects)
            $data = [ $copy ];
            $name = "hash";
        }
    }
    else {
        $copy = { %$self };
        $copy->{context} = "<removed>" if ($copy->{context});         # don't dump the reference to the context itself (Services)
        $copy->{_repository} = "<removed>" if ($copy->{_repository}); # don't dump the reference to the repository (RepositoryObjects)
        $data = [ $copy ];
        $name = $self->service_type() . "__" . $self->{name};
    }
    my $d = Data::Dumper->new($data, [ $name ]);
    $d->Indent(1);
    return $d->Dump();
}

#############################################################################
# print()
#############################################################################

=head2 print()

    * Signature: $service->print();
    * Param:     void
    * Return:    void
    * Throws:    App::Exception
    * Since:     0.01

    Sample Usage: 

    $service->print();

=cut

sub print {
    my $self = shift;
    print $self->dump();
}

#############################################################################
# substitute()
#############################################################################

=head2 substitute()

    * Signature: $result = $service->substitute($target);
    * Signature: $result = $service->substitute($target, $values);
    * Param:     $target         HASH,string
    * Param:     $values         HASH
    * Return:    $result         string
    * Throws:    App::Exception
    * Since:     0.01

    Sample Usage: 

    $welcome_message = $service->substitute("Welcome, {default-user}");

    my $auto_params = { user => "{default-user}", org_id => "{org_id}", };
    my $auto_values = { org_id => 1, };
    $params = $service->substitute($auto_params, $auto_values);

The substitute() method scans the $target string (or hash of strings) for
instances of variables (i.e. "{varname}") and makes substitutions.
It makes substitutions from a hash of $values if provided or from the
values of SessionObjects of the same name.

The substitute() method returns a string (or hash of strings) which is the
result of the substitution.

=cut

sub substitute {
    &App::sub_entry if ($App::trace);
    my ($self, $text, $values, $options) = @_;
    my ($phrase, $var, $value, $context, $default);
    $context = $self->{context};
    $values = {} if (! defined $values);

    if (ref($text) eq "HASH") {
        my ($hash, $newhash);
        $hash = $text;    # oops, not text, but a hash of text values
        $newhash = {};    # prepare a new hash for the substituted values
        foreach $var (keys %$hash) {
            $newhash->{$var} = $self->substitute($hash->{$var}, $values, $options);
        }
        &App::sub_exit($newhash) if ($App::trace);
        return($newhash); # short-circuit this whole process
    }

    my $undef_value = (defined $options->{undef_value}) ? $options->{undef_value} : "";

    # looking for patterns like the following: {user} {user:Guest}
    while ( $text =~ /\{([^\{\}:]+)(:[^\{\}]+)?\}/ ) {  # vars of the form {var}
        $var = $1;
        $default = $2;
        if (defined $values->{$var}) {
            $value = $values->{$var};
            $value = join(",", @$value) if (ref($value) eq "ARRAY");
        }
        else {
            $value = $context->so_get($var);
            $value = join(",", @$value) if (ref($value) eq "ARRAY");
        }
        if ((! defined $value || $value eq "") && $default ne "") {
            $default =~ s/^://;
            $value = $default;
        }
        elsif (!defined $value) {
            $value = $undef_value;
        }
        $text =~ s/\{$var(:[^\{\}]+)?\}/$value/g;
    }
    &App::sub_exit($text) if ($App::trace);
    $text;
}

#############################################################################
# get_sym_label()
#############################################################################

=head2 get_sym_label()

    * Signature: $label = $service->get_sym_label($sym);
    * Signature: $label = $service->get_sym_label($sym, $include_breaks, $label_dict, $lang_dict);
    * Param:     $sym            string
    * Param:     $include_breaks boolean
    * Param:     $label_dict     HASH
    * Param:     $lang_dict      HASH
    * Return:    $label          string

The get_sym_label() method turns a symbol (i.e. "begin_eff_dt") into a label
(i.e. "Begin <br>Effective <br>Date"). This label is suitable for use in
HTML drop-down lists and table column headings.

=cut

sub get_sym_label {
    &App::sub_entry if ($App::trace);
    my ($self, $sym, $include_breaks, $label_dict, $lang_dict) = @_;
    my ($label);
    $label = $label_dict->{$sym}{label} if ($label_dict && exists $label_dict->{$sym});
    if (! defined $label) {
        if (!$lang_dict) {
            my $context = $self->{context};
            my $default_object = $context->session_object();
            my $lang = $default_object->{lang} || "en";
            $lang_dict = $default_object->{dict}{$lang};
        }
        if ($lang_dict) {
            $label = $lang_dict->{$sym};
        }
    }
    if (! defined $label) {
        my @part = split(/_/, $sym);
        my $separator = $include_breaks ? " <br>" : " ";
        for (my $i = 0; $i <= $#part; $i++) {
            $part[$i] = $lang_dict->{$part[$i]} || ucfirst($part[$i]);
        }
        $label = join($separator, @part);
    }
    &App::sub_exit($label) if ($App::trace);
    return ($label);
}

#############################################################################
# PROTECTED METHODS
#############################################################################

=head1 Protected Methods:

The following methods are intended to be called by subclasses of the
current class.

=cut

#############################################################################
# Method: _init()
#############################################################################

=head2 _init()

The _init() method is called from within the standard Service
constructor.
It allows subclasses of the Service to customize the behavior of the
constructor by overriding the _init() method. 
The _init() method in this class simply calls the _init() 
method to allow each service instance to initialize itself.

    * Signature: _init($named)
    * Param:     $named      {}   [in]
    * Return:    void
    * Throws:    App::Exception
    * Since:     0.01

    Sample Usage: 

    $service->_init(\%args);

=cut

sub _init {
    my ($self, $args) = @_;
}

=head1 ACKNOWLEDGEMENTS

 * Author:  Stephen Adkins <spadkins@gmail.com>
 * License: This is free software. It is licensed under the same terms as Perl itself.

=head1 SEE ALSO

L<C<App>|App>,
L<C<App::Context>|App::Context>,
L<C<App::Conf>|App::Conf>

=cut

1;

