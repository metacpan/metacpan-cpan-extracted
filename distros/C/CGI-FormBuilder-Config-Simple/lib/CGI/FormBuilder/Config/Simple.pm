package CGI::FormBuilder::Config::Simple;

use warnings;
use strict;
use Carp;
use Data::Dumper;
use CGI::FormBuilder;

=head1 NAME

CGI::FormBuilder::Config::Simple - deploy web forms w/ .ini file  

=head1 VERSION

Version 0.12

=cut

our $VERSION = '0.12';

=head1 SYNOPSIS

This module exists to synthesize the abstractions of
CGI::FormBuilder with those of Config::Simple to make it nearly
possible to deploy a working form and database application
by simply configuring an ini file.  Add to that config file
your data processing routines, perhaps a template from the
design team and you are done.  This module handles converting
a config file into a form, validating user input and all that.

A developer would still be required to write methods to process
their data, but much of the rest of the work will be covered
by this modules' methods, and those of the ones just cited
from which it inherits its methods.

For some sample code, please see:
	t/My/Module/Test.pm
which provides scaffolding for the test suite.

    -- signup.cgi --

    use lib qw(lib);
    use MyModule::Signup;
        # see below for details . . . 

    my $debug_level = 0; # raise to 3 for noisy logs 
    my $signup = MyModule::Signup->new({ config_file => '/path/to/config/file.ini' });
        # should create a config object respecting ->param() method 
        # and embed that object at $self->{'cfg'}
    my $signup_form_html = $signup->render_web_form('sign_up',$debug_level) or
        carp("$0 died rendering a signup form. $signup->errstr. $!");

    print <<"END_OF_HTML";
    Content-Type: text/html; charset=utf-8 \n\n
    $signup_form_html
    END_OF_HTML

    1;

    -- /lib/MyModule/Signup.pm -- 

    package MyModule::Signup;

    use base 'CGI::FormBuilder::Config::Simple';

    sub new {
      my $class = shift;
      my $defaults = shift;
      my $self = {};

      $self->{'cfg'} = Config::Simple::Extended->new(
            { filename => $defaults->{'config_file'} } );
            # or use its ->inherit() method to overload configurations 

      my $db = $self->{'cfg'}->get_block('db');
      $self->{'dbh'} = MyModule::DB->connect($db);
            # a DBI->connect() object

      # whatever else you need in your constructor

      bless $self, $class;
      return $self;
    }

    sub sample_data_processing_method {
      my $self = shift;

        .  .  .  

      return;
    }

    sub get_that_field_options {
      my $self = shift;
      my @options = ('an_option','another_option');
      return \@options;
    }

    # the code above should render, validate and process your data 
    # Now write a config file looking like this, and your are done

    -- conf.d/apps.example.com/signup_form.ini --

    [db]
       . . . 


    [signup_form]
    
    template=/home/webapps/signup/conf.d/apps.example.com/tmpl/signup_form.tmpl.html
    fieldsets=sample_fieldset
    title='Signup Form'
    submit='Lets Get Started'
    header=1
    name='signup'
    method='post'
    debug=0
    # debug = 0 | 1 | 2 | 3
    reset=1
    fieldsubs=1
    keepextras=1
    custom_validation_methods=

    ;action=$script
    ;values=\%hash | \@array
    ;validate=\%hash
    ;required=[qw()]

    [signup_form_sample_fieldset]
    fields=this_field,that_field,another_field
    process_protocol=sample_data_processing_method
    enabled=1
    
    [signup_form_sample_fieldset_this_field]
    name=this_field
    label='This field'
    type=text
    fieldset=sample_fieldset
    require=1
    validate='/\w+/'
    validation_error='this_field should be made up of words'
    enabled=1
    
    [signup_form_sample_fieldset_that_field]
    name=that_field
    label='That field'
    type=select
    options=&get_that_field_options
    ;options=choice_a,choice_b,choice_c
    fieldset=sample_fieldset
    require=1
    validate=&get_that_field_options
    validation_error='that_field should include only legal options'
    enabled=1
    
    [signup_form_sample_fieldset_another_field]
       . . . 

=head1 METHODS 

=head2 ->render_web_form('form_name',$debug_level)

Given an object, with a configuration object accessible at
$self->{'cfg'}, honoring the ->param() method provided by
Config::Simple and Config::Simple::Extended (but possibly
others), render the html for a web form for service.

This method takes an optional second argument, used to set
the debug level.  Use 0 or undefined for quiet operation.

Use 1 or greater to see information about the form being
validated, 2 or greater to watch the fieldsets being validated,
3 or greater to watch the fields being validated and 4 or
greater to dump the contents of pre-defined field options
during field validation.

Use a 5 or greater to see information about the form being
built, 6 or greater to watch the fieldsets being built, 7 or
greater to watch the fields being built and 8 or greater to
dump the contents of pre-defined field options.

=cut

sub render_web_form {
  my $self = shift;
  my $form_name = shift;
  my $debug = shift || 0;

  my $form_attributes = $self->{'cfg'}->get_block("$form_name");
  my %attributes;
  FORM_ATTRIBUTE: foreach my $attribute (keys %{$form_attributes}){
    if($attribute eq 'custom_validation_methods'){ next FORM_ATTRIBUTE; }
    my $value = $form_attributes->{$attribute};
    $attributes{$attribute} = $value;
  }
  if($self->{'invalid'}){
    $attributes{'fields'} = $self->{'fields'};
  }
  my $form = CGI::FormBuilder->new( %attributes );
  $form->{'cgi_fb_cfg_simple_form_name'} = $form_name;
  if($debug > 0){
    print STDERR Dumper(\%attributes);
  }
  # print STDERR Dumper($form);

  my $html;
  my $fieldsets = $self->{'cfg'}->param("$form_name.fieldsets");
  my @fieldsets = split /,/,$fieldsets;

  # print Dumper(\@fieldsets);
  foreach my $fieldset (@fieldsets) {
    if($debug > 1){
      # print STDERR "Now building fieldset: " . Dumper($fieldset) . "\n";
    }
    $self->build_fieldset($form,$fieldset,$debug);
  }
  if ($form->submitted) {
    my $invalid = $self->validate_form($form,$debug);
    print STDERR "our \$invalid is: $invalid \n" if($debug > 1);
    unless($invalid){
      $html = $self->process_form($form,$debug);
    } else {
      $self->{'invalid'} = 1;
      $form->tmpl_param( DISPLAY_ERRORS => 1 );
      $form->tmpl_param( ERRORS => $self->errstr() );
      # print STDERR 'Our data validation errors include: ' . $self->errstr();
      $html = $form->render(header => $self->{'cfg'}->param("$form_name.header"));
    }
  } else {
    # Print out the form
    $html = $form->render(header => $self->{'cfg'}->param("$form_name.header"));
  }

  $self->{'form'} = $form;
  return $html;
}

=head2 $self->process_form($form,$debug_level)

In your My::Module which inherits from this one, you need
to write a method for every fieldset.process_protocol in the
configuration file.

This method will be called by the ->render_web_form() method
and cycle through each fieldset and execute your application
specific database interactions and other required data
processing.

=cut 

sub process_form {
  my $self = shift;
  my $form = shift;
  my $debug_level = shift;
  unless(defined($debug_level)){ $debug_level = 0; }
  my $field = $form->fields;
  my $form_name = $form->{'cgi_fb_cfg_simple_form_name'};

  print STDERR "Now processing form . . . \n"; # Dumper($field);

  my $fieldsets = $self->{'cfg'}->param("$form_name.fieldsets");
  my @fieldsets = split /,/,$fieldsets;

  my $html;
  foreach my $fieldset (@fieldsets) {
    my $stanza = $form_name . '_' . $fieldset;
    my $process_protocol = $self->{'cfg'}->param("$stanza.process_protocol");
    if($debug_level > 0){
      print STDERR "Our process_protocol is: $process_protocol for fieldset $stanza \n";
    }
    $html .= $self->$process_protocol($form_name,$field,$debug_level);
  }

  return $html;
}

=head2 ->validate_form()

This method validates each fieldset defined in the configuration
file for a form, returning 0 if all fields validate, and
otherwise a positive integer representing a count of  fields
which failed the validation test.

This method will also process each method listed in the
custom_validation_methods attribute of the stanza named for
the form.  Each of these methods, which must be written by
the user writing the module which inherits from this one,
should return a positive integer for invalid data or a zero
(0) if the data that method checks is valid.

=cut 

sub validate_form {
  my $self = shift;
  my $form = shift;
  my $debug = shift;

  my $invalid = 0;
  my $form_name = $form->{'cgi_fb_cfg_simple_form_name'};
  print STDERR "Now running ->validate_form() method for $form_name \n" if($debug > 0);

  my $fieldsets = $self->{'cfg'}->param("$form_name.fieldsets");
  my @fieldsets = split /,/,$fieldsets;

  foreach my $fieldset (@fieldsets) {
    if($debug > 0){
      print STDERR "Now validating fieldset: " . Dumper($fieldset) . "\n";
    }
    $invalid += $self->validate_fieldset($form,$fieldset,$debug);
  }

  my @custom_validation_methods = $self->{'cfg'}->param("$form_name.custom_validation_methods");
  foreach my $method (@custom_validation_methods){
    print STDERR "Now running ->$method() method for $form_name \n" if($debug > 1);
    $invalid += $self->$method($form,$debug);
  }
  return $invalid;
}

=head2 ->validate_fieldset()

This method validates each field defined in the configuration
file for a fieldset, returning 0 if all fields validate, and
otherwise a positive integer representing a count of fields
which failed the validation test.

=cut 

sub validate_fieldset {
  my $self = shift;
  my $form = shift;
  my $fieldset = shift;
  my $debug = shift;
  print STDERR "Now running ->validate_fieldset() method for $fieldset \n" if($debug > 1);

  my $invalid = 0;
  my $form_name = $form->{'cgi_fb_cfg_simple_form_name'};
  my $stanza = $form_name . '_' . $fieldset;
  if($debug > 1){
    print STDERR "->validate_fieldset() now validating $stanza \n";
  }
  if($self->{'cfg'}->param("$stanza.enabled")){
    my $stanza = $form_name . '_' . $fieldset;
    my $fields = $self->{'cfg'}->param("$stanza.fields");
    foreach my $field (@{$fields}) {
      my $field_stanza = $stanza . '_' . $field;
      if($debug > 1){
        # print STDERR "validating field: $field_stanza \n";
      }
      if($self->{'cfg'}->param("$field_stanza.enabled")){
        my $result = $self->validate_field($form,$fieldset,$field,$debug);
        print STDERR "$field is $form->$field and yields $result \n";
        $invalid += $result;
      }
    }
  } else {
    print STDERR "The $fieldset fieldset has not been enabled \n";
  }

  return $invalid;
}

=head2 ->validate_field()

This method validates a field, returning 0 if the field
validates, and otherwise 1.  It uses the validate attribute
from the configuration file to make a regex comparison.
If that validate has a value beginning with an ampersand '&',
the code reference is interpretted as an object method.  

This method must either return an array of array_references of
key->value pairs representing valid options (for a selector),
or otherwise an integer reflecting whether the field is invalid,
again 0 for valid or 1 for invalid.

The user must write the code reference in the module which
inherits from this one.

Presently having that coderef return the array of array_refs
has been tested, but the case where it returns 0 or 1, has
not yet been exercised in testing.  Buyer Beware and please
share your experience, bug reports, new test cases and patches.

=cut 

sub validate_field {
  my $self = shift;
  my $form = shift;
  my $fieldset = shift;
  my $field = shift;
  my $debug = shift;

  my $invalid = 0;
  my $form_name = $form->{'cgi_fb_cfg_simple_form_name'};
  my $field_stanza = $form_name . '_' . $fieldset . '_' . $field;

  if($self->{'cfg'}->param("$field_stanza.enabled")){
    print STDERR "Now running ->validate_field() method for $fieldset.$field \n" if($debug > 2);
    if($self->{'cfg'}->param("$field_stanza.validate") !~ m/^&/){
      my $regex = $self->{'cfg'}->param("$field_stanza.validate");
      $regex =~ s/^\///;
      $regex =~ s/\/$//;
      if($self->{'cfg'}->param("$field_stanza.require")){
        if($form->$field =~ m/$regex/){
          $invalid = 0;
        } elsif(!(length($form->$field))){
          $invalid = 1;
        } elsif(!(defined($form->$field))){
          $invalid = 1;
        } elsif (defined($form->$field) && $form->$field eq ''){
          $invalid = 1;
        } else {
          $invalid = 1;
        }
      } else {
        if($form->$field =~ m/$regex/){
          $invalid = 0;
        } elsif($form->$field eq '' || !defined($form->$field)){
          $invalid = 0;
        } else {
          $invalid = 1;
        }
      }
    } else {
      my $options = $self->{'cfg'}->param("$field_stanza.validate");
      $options =~ s/^&//;
      my $valid_options = $self->$options() || $self->errstr("write a method called ->$options");
      print STDERR Dumper($valid_options) if($debug > 3);
      $invalid = 1;
      if(ref($valid_options) eq 'ARRAY'){
        FIELD_OPTION: foreach my $option (@{$valid_options}){
          my ($key,$value) = @{$option};
          if($form->$field =~ $key){
            $invalid = 0;
            last FIELD_OPTION;
          }
        }
      } else {
        # this branch has not yet been tested . . . 
        $invalid = $valid_options;
      }
    }
  }

  if($invalid){
    my $msg = 'For field: ' . $field . ', our value is: ';
    $msg .= $form->$field if(defined($form->$field));
    $msg .= ' and validation rule is: ' . $self->{'cfg'}->param("$field_stanza.validate");
    $self->errstr($msg) if($debug > 2);
    $self->errstr($self->{'cfg'}->param("$field_stanza.validation_error"));
  }

  return $invalid;
}

=head2 $self->build_fieldset($form,$fieldset,$debug_level)

Parses the configuration object for the fields required to
build a form's fieldset and calls ->build_field() for each
field listed in the fields attribute of the fieldset stanza
in that configuration file, to compile the pieces necessary
to configure the CGI::FormBuilder $form object.

=cut

sub build_fieldset {
  my $self = shift;
  my $form = shift;
  my $fieldset = shift;
  my $debug = shift;

  # print STDERR "Now being asked to build a fieldset \n";
  my $form_name = $form->{'cgi_fb_cfg_simple_form_name'};
  my $stanza = $form_name . '_' . $fieldset;
  if($debug > 5){
    print STDERR "->build_fieldset() now processing $stanza \n";
  }
  if($self->{'cfg'}->param("$stanza.enabled")){
    my $stanza = $form_name . '_' . $fieldset;
    my $fields = $self->{'cfg'}->param("$stanza.fields");
    foreach my $field (@{$fields}) {
      my $field_stanza = $stanza . '_' . $field;
      if($debug > 5){
        print STDERR "seeking field stanza: $field_stanza \n";
      }
      unless($self->{'cfg'}->param("$field_stanza.disabled")){
        # print STDERR Dumper($field),"\n";
        $self->build_field($form,$fieldset,$field,$debug);
      }
    }
  } else {
    print STDERR "The $fieldset fieldset has not been enabled \n";
  }
  return;
}

=head2 $self->build_field($form,$fieldset,$field,$debug_level)

Parses the configuration object for the attributes used to
configure a CGI::FormBuilder->field() object.  In reading
the field attributes from the configuration file, it ignores
'validation_error', 'enabled' and the now deprecated 'disabled'.

=cut

sub build_field {
  my $self = shift;
  my $form = shift;
  my $fieldset = shift;
  my $field = shift;
  my $debug = shift;

  my $form_name = $form->{'cgi_fb_cfg_simple_form_name'};
  my $block = $form_name . '_' . $fieldset . '_' . $field;
  if($debug > 6){
    print STDERR "Our next block is: $block \n";
  }
  my $field_attributes = $self->{'cfg'}->get_block($block);

  my @attributes;
  FIELD_ATTRIBUTE: foreach my $attribute (keys %{$field_attributes}){
    if($debug > 6){
      print STDERR "My attribute is: $attribute \n";
    }
    my @values = ();
    if($attribute eq 'validation_error'){ next FIELD_ATTRIBUTE; }
    if($attribute eq 'enabled'){ next FIELD_ATTRIBUTE; }
    if($attribute eq 'disabled'){ next FIELD_ATTRIBUTE; }
    my $value = $field_attributes->{$attribute};
    if(defined($value)){
      if($value =~ m/^&/){
        $value =~ s/^&//;
        my $values = $self->$value() || $self->errstr("write a method called ->$value");
        if($attribute eq 'label'){
          if($debug > 6){
            print STDERR Dumper($values);
          }
          push @attributes, $attribute => $values;
        } elsif($attribute eq 'options'){
          if(ref($values) eq 'ARRAY'){
            if($debug > 7){
              print STDERR Dumper(\@{$values});
            }
            push @attributes, $attribute => \@{$values};
          } elsif(ref($values) eq 'HASH'){
            if($debug > 7){
              print STDERR Dumper(\%{$values});
            }
            push @attributes, $attribute => \%{$values};
          } else {
            print STDERR '$values is ' . Dumper($values);
          }
        } elsif($attribute eq 'value'){
          if($debug > 6){
            print STDERR Dumper(\@{$values});
          }
          push @attributes, $attribute => \@{$values};
        }
      } elsif($value !~ m/^&/) {
        push @attributes, $attribute => $value;
      } else {
        print STDERR "Failed to catch and handle $value for $attribute \n";
      }
    }
  }

  $form->field(@attributes);
  return;
}

=head2 errstr('Error description')

Append its argument, if any, to the error string, and return
the result, returning undef if no error message has been set.
Each error is prepended with a <li> list item tag, and the
results are imagined to be rendered in html between <ul>
unordered list tags.

=cut

sub errstr {
  my $self = shift;
  my $error = shift || '';
  $self->{'errstr'} .= "<li>" . $error . "\n" if(defined($error) && ($error ne '') );
  return $self->{'errstr'};
}

=head1 AUTHOR

Hugh Esco, C<< <hesco at campaignfoundations.com> >>

=head1 BUGS

Please report any bugs or feature requests
to C<bug-cgi-formbuilder-config-simple
at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-FormBuilder-Config-Simple>.
I will be notified, and then you'll automatically be notified
of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CGI::FormBuilder::Config::Simple

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-FormBuilder-Config-Simple>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CGI-FormBuilder-Config-Simple>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CGI-FormBuilder-Config-Simple>

=item * Search CPAN

L<http://search.cpan.org/dist/CGI-FormBuilder-Config-Simple/>

=back

=head1 ACKNOWLEDGEMENTS

My appreciation to our team at YMD Partners, LLC, Bruce Dixon
and Ida Hakim.  Thank you for being a part of this business
and for the contributions you make to serving our clients.

I want to acknowledge the support of the Green Party of Texas
for making possible development of this module.  An exciting
if simple project of theirs serves as the first real world test
of this idea which had been kicking about my head for a while.

And of course this work would not have been possible without
the prior contributions to the CPAN repository made by Sherzod
Ruzmetov, author of Config::Simple and Nate Wiger, author of
CGI::FormBuilder, nor of course all the brilliant folks who
developed Perl.

=head1 COPYRIGHT & LICENSE

Copyright 2010 Hugh Esco.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; version 2 dated
June, 1991 or at your option any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

A copy of the GNU General Public License is available in the source tree;
if not, write to the Free Software Foundation, Inc.,
59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

=cut

1; # End of CGI::FormBuilder::Config::Simple
