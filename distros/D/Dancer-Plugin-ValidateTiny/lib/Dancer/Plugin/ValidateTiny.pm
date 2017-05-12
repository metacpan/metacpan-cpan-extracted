package Dancer::Plugin::ValidateTiny;

use strict;
use warnings;

use Dancer ':syntax';
use Dancer::Plugin;
use Validate::Tiny ':all';
use Email::Valid;


our $VERSION = '0.06';

my $settings = plugin_setting;


register validator => sub
{
	my ($params, $rules_file) = @_;

	my $result = {};

	# Loading rules from file
	my $rules = _load_rules($rules_file);

	# Validating
	my $validator = Validate::Tiny->check($params, $rules);

	# If you need a full Validate::Tiny object
	if($settings->{is_full} eq 1)
	{
		return $validator;
	}

	if($validator->success)
	{
		# All ok
		$result = {
			result => $validator->data,
			valid => $validator->success
			};
	}
	else
	{
		# Returning errors
		if(exists $settings->{error_prefix})
		{
			# With error prefixes from config
			$result = {
				result => _set_error_prefixes($validator->error),
				valid => $validator->success
				};
		}
		else
		{
			# Without error prefixes
			$result = {
				result => $validator->error,
				valid => $validator->success
				};
		}
	}

	# Combining filtered params and validation results
	%{$result->{result}} = (%{$result->{result}}, %{$validator->data});

	# Returning validated data
	return $result;
};

sub _set_error_prefixes
{
	my $errors = shift;

	foreach my $error (keys %{$errors})
	{
		# Replacing keys with prefix. O_o
		$errors->{$settings->{error_prefix} . $error} = delete $errors->{$error};
	}

	return $errors;
}

sub _load_rules
{
	my $rules_file = shift;

	# Checking plugin settings and rules file for existing
	die "Rules directory not specified in plugin settings!" if !$settings->{rules_dir};
	die "Rules file not specified!" if !$rules_file;

	# Making full path to rules file
	$rules_file = setting('appdir') . '/' . $settings->{rules_dir} . "/" . $rules_file;

	# Putting rules from file to $rules
	my $rules = do $rules_file || die $! . "\n" . $@;

	return $rules;
}


sub check_email
{
	my ($email, $message) = @_;
	Email::Valid->address($email) ? undef : $message;
}


register_plugin;


1;
__END__

=head1 NAME

Dancer::Plugin::ValidateTiny - Validate::Tiny Dancer plugin.

=head1 VERSION

Version 0.06

=head1 SYNOPSIS

Easy and cool validating data with L<Validate::Tiny> module:

    use Dancer::Plugin::ValidateTiny;
    
    post '/' => sub {
        my $params = params;
        my $data_valid = 0;
    
        # Validating params with rule file
        my $data = validator($params, 'form.pl');
    
        if($data->{valid}) { ... }
    };

Rule file is pretty too:

    {
        # Fields for validating
        fields => [ qw/login email password password2/ ],
        filters => [
            qr/.+/ => filter(qw/trim strip/),    
            email => filter('lc'),
        ],
        checks => [
            [ qw/login email password password2/ ] => is_required("Field required!"),
            
            login => is_long_between( 2, 25, 'Your login should have between 2 and 25 characters.' ),
            email => sub {
                check_email($_[0], "Please enter a valid email address.");
                },
            password => is_long_between( 4, 40, 'Your password should have between 4 and 40 characters.' ),
            password2 => is_equal("password", "Passwords don't match"),
        ],
    }

Note, that C<@_> in anonymous sub in C<checks> section contains value to be checked
and a reference to the filtered input hash. Check L<Validate::Tiny> documentation for
this.


=head1 DESCRIPTION

Simple Dancer plugin for use L<Validate::Tiny> module.

It provides simple use for L<Validate::Tiny> way of validating user input with
Dancer applications with some additions and modifications, such as separate files
for rules and additional functions for data validation.

=head1 METHODS

=head2 validator

This is the main method, that receiving C<params> from C<POST> or C<GET> (or whatever), and
filename, which contains rules for validation:

    my $params = params;
    my $data = validator($params, 'form.pl');

After this, in C<$data> you'll have a structure like:

    {
      'valid' => 0,
      'result' => {
                  'err_login' => 'Your login should have between 4 and 25 characters.',
                  'err_email' => 'Please enter a valid email address.',
                  'err_password' => 'Field required!'
                  'login' => 'foo',
                  'email' => 'test input',
                  'password' => ''
                }
    };

Where C<valid> field is an indicator, that you can use like C<if($data-E<gt>{valid}) { ... }>.

And C<result> field, that contains B<already filtered> params and error messages for
them with special prefixes. Note, that you can set up L</error_prefix> in config file.

=head1 RULE FILES

In your Dancer application directory you need to create sub-directory for rule files
and place here rules, that you will use for validation. In this files you need to create
a simple structure like this one:

    {
        fields => [qw/city zip_code/],
        checks => [
            [qw/city zip_code/] => is_required("Field required!"),
            
            city => is_long_at_most( 40, 'City name is too long' ),
            zip_code => is_long_at_least( 5, 'Bad zip code' ),
        ],
    }

For other rules, you can refer to the documentation of L<Validate::Tiny> module.

After creating rule file, you just need to specify it's name in L</validator> method.
Simple, yeah? :)


=head1 ADDITIONAL RULES

There is some additional subroutines, that you can use in rule files:

=head2 check_email

    {
        fields => "email",
        filters => [
            email => filter('trim', 'strip', 'lc')
        ],
        checks => [
            email => sub { check_email($_[0], "Please enter a valid e-mail address.") },
        ],
    }

This subroutine checking e-mail address conforms to the RFC822 specification with L<Email::Valid>.

Note, that C<checks> processing data, that B<already filtered> by C<filters>.

=head1 CONFIG

In your config file you can use these settings:

    plugins:
      ValidateTiny:
        rules_dir: validation
        error_prefix: err_
        is_full: 0

Where:

=head2 rules_dir

Directory, where you will store your rule files. Plugin looking it in your Dancer
application root.

=head2 error_prefix

Prefix, that used to separate error fields from normal values in C<result> hash.
It is very convenient when you use the template engine, such as L<Template::Toolkit>
or L<HTML::Template>. You simply pass the data to the template engine, and it handles
the logic of output errors and/or warnings for user.

=head2 is_full

If this option is set to C<1>, call of C<validator> returning
an object, that you can use as standart L<Validate::Tiny> object.

=head1 SEE ALSO

L<Validate::Tiny> L<Dancer::Plugin::FormValidator> L<Dancer::Plugin::DataFu>

=head1 AUTHOR

Alexey Kolganov, C<< <kalgan@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Alexey Kolganov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
