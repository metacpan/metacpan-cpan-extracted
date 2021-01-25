#
# This file is part of Config-Model-Backend-Yaml
#
# This software is Copyright (c) 2018 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Config::Model::Backend::Yaml;
$Config::Model::Backend::Yaml::VERSION = '2.134';
use 5.10.1;
use Carp;
use strict;
use warnings;
use Config::Model 2.131;
use Config::Model::Exception;
use File::Path;
use Log::Log4perl qw(get_logger :levels);
use boolean;
use YAML::XS 0.69;

use base qw/Config::Model::Backend::Any/;

my $logger = get_logger("Backend::Yaml");

sub single_element {
    my $self = shift;

    my @elts = $self->node->children;
    return if @elts != 1;

    my $obj = $self->node->fetch_element($elts[0]);
    my $type = $obj->get_type;
    return $type =~ /^(list|hash)$/ ? $obj : undef ;
}

sub read {
    my $self = shift;
    my %args = @_;

    local $YAML::XS::LoadBlessed = 0;

    # args is:
    # object     => $obj,         # Config::Model::Node object
    # root       => './my_test',  # fake root directory, userd for tests
    # config_dir => /etc/foo',    # absolute path
    # file       => 'foo.conf',   # file name
    # file_path  => './my_test/etc/foo/foo.conf'
    # check      => yes|no|skip

    return 0 unless $args{file_path}->exists;    # no file to read

    # load yaml file
    my $yaml = $args{file_path}->slurp_raw;

    # convert to perl data
    my $perl_data = Load($yaml) ;
    if ( not defined $perl_data ) {
        my $msg = "No data found in YAML file $args{file_path}";
        if ($args{auto_create}) {
            $logger->info($msg);
        }
        else {
            $logger->warn($msg);
        }
        return 1;
    }

    my $target = $self->single_element // $self->node ;

    # load perl data in tree
    $target->load_data( data => $perl_data, check => $args{check} || 'yes' );
    return 1;
}

sub write {
    my $self = shift;
    my %args = @_;

    # args is:
    # object     => $obj,         # Config::Model::Node object
    # root       => './my_test',  # fake root directory, userd for tests
    # config_dir => /etc/foo',    # absolute path
    # file       => 'foo.conf',   # file name
    # file_path  => './my_test/etc/foo/foo.conf'
    # check      => yes|no|skip

    local $YAML::XS::Boolean = "boolean";

    my $target = $self->single_element // $self->node ;

    my $perl_data = $target->dump_as_data(
        full_dump => $args{full_dump} // 0,
        to_boolean => sub { return boolean($_[0]) }
    );

    my $yaml = Dump( $perl_data );

    $args{file_path}->spew_raw($yaml);

    return 1;
}

1;

# ABSTRACT: Read and write config as a YAML data structure

__END__

=pod

=encoding UTF-8

=head1 NAME

Config::Model::Backend::Yaml - Read and write config as a YAML data structure

=head1 VERSION

version 2.134

=head1 SYNOPSIS

 use Config::Model ;
 use Data::Dumper ;

 # define configuration tree object
 my $model = Config::Model->new ;
 $model ->create_config_class (
    name => "MyClass",
    element => [ 
        [qw/foo bar/] => { 
            type => 'leaf',
            value_type => 'string'
        },
        baz => { 
            type => 'hash',
            index_type => 'string' ,
            cargo => {
                type => 'leaf',
                value_type => 'string',
            },
        },
    ],
  rw_config  => {
    backend => 'yaml',
    config_dir => '/tmp',
    file  => 'foo.yml',
    auto_create => 1,
  }
 ) ;

 my $inst = $model->instance(root_class_name => 'MyClass' );

 my $root = $inst->config_root ;

 my $steps = 'foo=yada bar="bla bla" baz:en=hello
             baz:fr=bonjour baz:hr="dobar dan"';
 $root->load( steps => $steps ) ;
 $inst->write_back ;

Now, C</tmp/foo.yml> contains:

 ---
 bar: bla bla
 baz:
   en: hello
   fr: bonjour
   hr: dobar dan
 foo: yada

=head1 DESCRIPTION

This module is used directly by L<Config::Model> to read or write the
content of a configuration tree written with YAML syntax in
C<Config::Model> configuration tree.

Note:

=over 4

=item *

Undefined values are skipped for list element. I.e. if a
list element contains C<('a',undef,'b')>, the data structure
contains C<'a','b'>.

=item *

YAML file is not created (and may be deleted) when no data is to be
written.

=back

=head2 Class with only one hash element

If the root node contains a single hash or list element, only the
content of this hash is written in a YAML file.

For example, if a class contains:

      element => [
        baz => {
            type => 'hash',
            index_type => 'string' ,
            cargo => {
                type => 'leaf',
                value_type => 'string',
            },
        },

If the configuration is loaded with:

 $root->load("baz:one=un baz:two=deux")

Then the written YAML file does B<not> show C<baz>:

 ---
 one: un
 two: deux

Likewise, a YAML file for a class with a single list C<baz> element
would be written with:

 ---
 - un
 - deux

=head1 YAML class

As of v2.129, this backend uses L<YAML::XS> 0.69 or later.

For security reason, loading a Perl blessed object is disabled.

Value of type boolean are written as boolean values in YAML files.

=head1 backend parameter

=head2 yaml_class

This parameter is ignored as of version 2.129.

=head1 CONSTRUCTOR

=head2 new

Parameters: C<< ( node => $node_obj, name => 'yaml' ) >>

Inherited from L<Config::Model::Backend::Any>. The constructor is
called by L<Config::Model::BackendMgr>.

=head2 read

Read YAML file and load into C<$node_obj> tree.

When a file is read, C<read> returns 1.

=head2 write

Write YAML File using C<$node_obj> data.

C<write> returns 1.

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model>, L<Config::Model::BackendMgr>,
L<Config::Model::Backend::Any>, L<YAML::XS>

=head1 AUTHOR

Dominique Dumont

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Dominique Dumont.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/Config-Model-Backend-Yaml>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/C/Config-Model-Backend-Yaml>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Config-Model-Backend-Yaml>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Config::Model::Backend::Yaml>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<ddumont at cpan.org>, or through
the web interface at L<https://github.com/dod38fr/config-model-backend-yaml/issues>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<http://github.com/dod38fr/config-model-backend-yaml>

  git clone git://github.com/dod38fr/config-model-backend-yaml.git

=cut
