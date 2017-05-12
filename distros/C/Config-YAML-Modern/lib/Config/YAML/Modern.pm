package Config::YAML::Modern;

use 5.008;
use strict;
use warnings;

=head1 NAME

Config::YAML::Modern - Modern YAML-based config loader from file or directory.

=head1 VERSION

Version 0.36

=cut

our $VERSION = '0.36';
$VERSION = eval $VERSION;

# develop mode only
# use Smart::Comments;

# die beautiful
use Carp qw/croak/;

# too match for directory-based loader
use File::Basename qw/dirname fileparse/;
use File::Spec;
use File::Glob qw/:glob/;

# srsly who care about your YAML lib :) I`nt!
use YAML::Any qw/LoadFile/;

# its for correct hash creation + for data mining
use Data::Diver qw/DiveVal DiveDie Dive/;

# so, its smartest way for Merge hash
use Hash::Merge;

=head1 SYNOPSIS

Config::YAML::Modern created to get dial with yaml-based configuration.

Its possible to load single file, or all files in one directory (without recursion search).

Data from many files was be merged properly (almost), also filename was be converted
to top-level hash keys.

Filename like 'file.data.yaml' was be converted to { file => { data => $file_content } }.

Also module provide perfect dive() interface form Data::Diver.

It may be used like 

	my $file_content = $conf_object->dive(qw/file data/);
	

Simply usage for file load

    use Config::YAML::Modern;

    my $config = Config::YAML::Modern->new();
    
    my $filename = 'test.yaml';
    
    $config->load_file($filename);
    
    my $data = $config->config();


More complicated for directory-based loading

    my $config2 = Config::YAML::Modern->new( key_conversion => 'ucfirst' );
    
    my $directory = '/etc/my_app/';
    
    # slurp all data to hashref
    my $data2 = $config2->load_dir($directory)->config();
    
    # but exist more sophisticated path
    my @list_of_key = (qw/Model Message 0 author/);
    my $data3 = $config2->dive(@list_of_key);
    
    # $data3 == $data2->{Model}{Message}[0]{author}


=cut

# our error text for sprintf
my $err_text = [
    qq( filename is required ),
    qq( file |%s| is not exists ),
    qq( dont know |%s| conversion ),
    qq( error on parsing file |%s| with message: %s ),
    qq( directory name is required ),
    qq( directory |%s| is not exists ),
    qq( suffix is required, or you must set 'i_dont_use_suffix property' ),
    qq( no one file matched with |%s| pattern at |%s| directory ),
    qq( call with empty args deprecated ),
    qq( only hashref are allowed ),

];

# its our private subs
my ( $key_conversion, $get_files_list );

=head1 SUBROUTINES/METHODS

=cut

=head2 new

new( [ list of args ] ) - create Config::YAML::Modern object and return it.

	my $config = Config::YAML::Modern->new();

The options currently supported are:

=over 4

=item * C<merge_behavior>
behavior on merge data, see L<Hash::Merge> docs. 

Available values are [LEFT_PRECEDENT, RIGHT_PRECEDENT, STORAGE_PRECEDENT, RETAINMENT_PRECEDENT],
'LEFT_PRECEDENT' by default.

=item * C<file_suffix>
File suffix, used in search files in directory for matching. '.yaml' by default.

=item * C<key_conversion>
Rule for conversion parts of filename to hash keys.

Available values are [undef, uc, ucfirst, lc, lcfirst]. No conversion  - 'undef' by default.

=item * C<i_dont_use_suffix>
Set to true if you not use suffix on config files. Suffix is used by default - 'undef'.

=item * C<__force_return_data>
If setted to true, methods: load_file(), load_dir(), add_hash(), add_file() and add_dir()
returns dataset instead of $self, returned by default - 'undef'.

!!! important - in this case loaded or added data are NOT BE STORED in object, use it well

=item * C<ignore_empty_file>
If setted to true method:

	- load_file() will return or assign to object empty flat hash without created keys by file name - just {}.

	- load_dir() will ignore empty files and not been add keys by names of empty files at all

	- add_file() and add_dir() will ignore empty files and not use it in merge process

By default empty files NOT ignored, value by default - 'undef'.

=back

=cut

sub new {

    my $class = shift;
    my $arg   = {
        __config            => {},
        merge_behavior      => 'LEFT_PRECEDENT',
        file_suffix         => '.yaml',
        key_conversion      => undef,
        i_dont_use_suffix   => undef,
        __force_return_data => undef,
        ignore_empty_file   => undef,
        @_
    };

    my $self = bless( $arg, ref $class || $class );

    return $self;
}

=head2 load_file

load_file($filename) - load data from yaml-contained file

	$config->load_file($filename);

=cut

sub load_file {
    my $self     = shift;
    my $filename = shift;

    unless ( defined $filename ) {
        croak sprintf $err_text->[0];
    }

    unless ( -e $filename ) {
        croak sprintf $err_text->[1], $filename;
    }

    # this block for filename to hash key resolving
    # et my.config.yaml -> { my => { config => { $data_here } } }
    my ( $filename_for_hash, undef, $suffix ) =
      fileparse( $filename, qr/\.[^.]*/ );
    my @file_part = split m/\./, $filename_for_hash;

    # I care about all of you, but it bad practice!!!
    if ( defined $self->{'i_dont_use_suffix'} ) {
        $suffix =~ s/^\.//;

        # fix empty key addition
        push @file_part, $suffix if ( $suffix ne '' );
    }

    # if we are need key conversation
    my $key_conv = $self->{key_conversion};
    @file_part = $key_conversion->( $key_conv, @file_part )
      if ( defined $key_conv );

    # now we are go to load file
    my $config_value = {};
    my $temp_val;

    eval { $temp_val = LoadFile($filename) };

    croak sprintf $err_text->[3], $filename, $@ while ($@);

    DiveVal( $config_value, @file_part ) = $temp_val;

    # return empty hash if file empty to suppress vanish data by empty file
    if ( !defined $temp_val && defined $self->{'ignore_empty_file'} ) {

        $config_value = {};
    }

    # for dir_load, or you are may use it, if you want
    return $config_value while ( defined $self->{__force_return_data} );

    # or get classical $self for chaining
    $self->{'__config'} = $config_value;
    return $self;

}

=head2 load_dir

load_dir($directory) - get files from directory (non-recursive), load data and merge it together

	$config2->load_dir($directory);

=cut

sub load_dir {
    my $self = shift;
    my $dir  = shift;

    unless ( defined $dir ) {
        croak sprintf $err_text->[4];
    }

    unless ( -d $dir ) {
        croak sprintf $err_text->[5], $dir;
    }

    my @file_list = $get_files_list->( $self, $dir );

    # its hack, but I`m not shined
    my $return_data_flag = $self->{'__force_return_data'};
    $self->{'__force_return_data'} = 1;

    #ok, little-by-little take our config
    my %result;

    # LEFT_PRECEDENT is almost right way
    my $merger = Hash::Merge->new( $self->{'merge_behavior'} );

    foreach my $full_filename (@file_list) {

        my $temp_val = $self->load_file($full_filename);

        # just ignore empty files
        next
          if (!scalar keys %$temp_val
            && defined $self->{'ignore_empty_file'} );

        # make smart deep merge
        %result = %{ $merger->merge( \%result, $temp_val ) };

    }

    # change it back
    $self->{'__force_return_data'} = $return_data_flag;

    # you are may use it, if you want
    return \%result while ( defined $self->{__force_return_data} );

    # or get classical $self for chaining
    $self->{'__config'} = \%result;
    return $self;
}

=head2 add_hash

add_hash($hash_ref, $behavior? ) - add data to object from hash with $behavior resolution, or use default behavior.

	my $data3 = $config2->add_hash( $hash_ref, 'RIGHT_PRECEDENT' );

Just wrapper ontop of L<Hash::Merge/"merge">

=cut

sub add_hash {
    my $self     = shift;
    my $hash_ref = shift;
    my $behavior = shift;

    croak sprintf $err_text->[8] unless ( defined $hash_ref );

    croak sprintf $err_text->[9] unless ( ref $hash_ref eq 'HASH' );

    # LEFT_PRECEDENT is almost right way
    my $merger = Hash::Merge->new( $behavior || $self->{'merge_behavior'} );

    # make smart deep merge
    my %result = %{ $merger->merge( $self->{'__config'}, $hash_ref ) };

    # you are may use it, if you want
    return \%result while ( defined $self->{__force_return_data} );

    # or get classical $self for chaining
    $self->{'__config'} = \%result;
    return $self;

}

=head2 add_file

add_file($filename, $behavior? ) - add data to object from file with $behavior resolution, or use default behavior.

	my $data3 = $config2->add_file( $filename3, 'RIGHT_PRECEDENT' );

=cut

sub add_file {
    my $self     = shift;
    my $filename = shift;
    my $behavior = shift;

    # its hack, but I`m not shined
    my $return_data_flag = $self->{'__force_return_data'};
    $self->{'__force_return_data'} = 1;

    my $result;
    my $temp_val = $self->load_file($filename);

    # just ignore empty files
    if ( !scalar keys %$temp_val && defined $self->{'ignore_empty_file'} ) {
        $result = $self->{'__config'};
    }
    else {
        $result = $self->add_hash( $temp_val, $behavior );
    }

    # change it back
    $self->{'__force_return_data'} = $return_data_flag;

    # you are may use it, if you want
    return $result while ( defined $self->{__force_return_data} );

    # or get classical $self for chaining
    $self->{'__config'} = $result;
    return $self;

}

=head2 add_dir

add_dir($dir_name, $behavior? ) - add data to object from directory with $behavior resolution, or use default behavior.

	my $data3 = $config2->add_dir( $dir_name2, 'RETAINMENT_PRECEDENT' );

=cut

sub add_dir {
    my $self     = shift;
    my $dir_name = shift;
    my $behavior = shift;

    # its hack, but I`m not shined
    my $return_data_flag = $self->{'__force_return_data'};
    $self->{'__force_return_data'} = 1;

    my $result;
    my $temp_val = $self->load_dir($dir_name);

    # just ignore empty files
    if ( !scalar keys %$temp_val && defined $self->{'ignore_empty_file'} ) {

        $result = $self->{'__config'};
    }
    else {
        $result = $self->add_hash( $temp_val, $behavior );
    }

    # change it back
    $self->{'__force_return_data'} = $return_data_flag;

    # you are may use it, if you want
    return $result while ( defined $self->{__force_return_data} );

    # or get classical $self for chaining
    $self->{'__config'} = $result;
    return $self;

}

=head2 dive

dive(@list_of_key) - return data from object by @list_of_key patch resolution, return "undef" if path resolution wrong.

	my $data3 = $config2->dive(@list_of_key);

Just wrapper ontop of L<Data::Diver/"Dive">

=cut

sub dive {
    my $self        = shift;
    my @list_of_key = @_;

    croak sprintf $err_text->[8] while ( $#list_of_key < 0 );

    my $value = Dive( $self->{'__config'}, @list_of_key );

    return $value;
}

=head2 dive_die

dive_die(@list_of_key) - return data from object by @list_of_key patch resolution, and do "die" if path resolution wrong.

	my $data3 = $config2->dive_die(@list_of_key);

Just wrapper ontop of L<Data::Diver/"DiveDie">

=cut

sub dive_die {
    my $self        = shift;
    my @list_of_key = @_;

    croak sprintf $err_text->[8] while ( $#list_of_key < 0 );

    my $value = DiveDie( $self->{'__config'}, @list_of_key );

    return $value;
}

=head2 config

config() - return all config data from object

	my $data = $config->config();

=cut

sub config {
    my $self = shift;
    return $self->{'__config'};
}

#=======
# internal functions
#=======

=begin comment key_conversion

subroutine for convert filepart

=end comment

=cut

$key_conversion = sub {

    my $key_conv = shift;
    my @part_in  = @_;
    my @part_out;

    # yes! it`s noisy and ugly, get 5.14 and it will by pretty
    if ( $key_conv eq 'uc' ) {
        @part_out = map { uc $_ } @part_in;
    }
    elsif ( $key_conv eq 'ucfirst' ) {
        @part_out = map { ucfirst $_ } @part_in;
    }
    elsif ( $key_conv eq 'lc' ) {
        @part_out = map { lc $_ } @part_in;
    }
    elsif ( $key_conv eq 'lcfirst' ) {    # ok, but why???
        @part_out = map { lcfirst $_ } @part_in;
    }
    else {    # add another one by yourself or get error
        croak sprintf $err_text->[2], $key_conv;
    }

    return @part_out;
};

=begin comment get_files_list

subroutine for get all files from directory

=end comment

=cut

$get_files_list = sub {
    my $self = shift;
    my $dir  = shift;

    my $glob = '*.';

    if ( !defined $self->{'i_dont_use_suffix'} ) {

        croak sprintf $err_text->[6] unless ( defined $self->{'file_suffix'} );

        # just throw out the dot
        my ($suffix) = $self->{'file_suffix'} =~ /([^.]+)$/;
        $glob .= $suffix;

    }
    else {
        $glob = '*';    # yes, just '*' pattern
    }

    my $full_pattern = File::Spec->catfile( $dir, $glob );

    # get all files in our dir
    # REMEMBER!! no recursive search and e.t.c. - just plain dir scan!!!
    my @file_list = bsd_glob( $full_pattern, GLOB_MARK );

    # so, we are must filter directory in this case
    if ( defined $self->{'i_dont_use_suffix'} ) {
        @file_list = grep { !m'/$' } @file_list;
    }

    croak sprintf $err_text->[7], $glob, $dir while ( $#file_list < 0 );

    return @file_list;

};

=head1 DEPRECATED METHODS

The old module interface is still available, but its use is discouraged. It will eventually be removed from the module.

=cut

=head2 file_load

file_load($filename) - load data from yaml-contained file

	$config->file_load($filename);

=cut

sub file_load {
    goto &load_file;
}

=head2 dir_load

dir_load($directory) - get files from directory, load data and merge it together

	$config2->dir_load($directory);

=cut

sub dir_load {
    goto &load_dir;
}

=head2 hash_add

hash_add($hash_ref, $behavior? ) - add data to object from hash with $behavior resolution, or use default behavior.

	my $data3 = $config2->hash_add( $hash_ref, 'RIGHT_PRECEDENT' );

Just wrapper ontop of L<Hash::Merge/"merge">

=cut

sub hash_add {
    goto &add_hash;
}

=head2 file_add

file_add($filename, $behavior? ) - add data to object from file with $behavior resolution, or use default behavior.

	my $data3 = $config2->file_add( $filename3, 'RIGHT_PRECEDENT' );

=cut

sub file_add {
    goto &add_file;
}

=head2 dir_add

file_add($dir_name, $behavior? ) - add data to object from directory with $behavior resolution, or use default behavior.

		my $data3 = $config2->dir_add( $dir_name2, 'RETAINMENT_PRECEDENT' );

=cut

sub dir_add {
    goto &add_dir;
}

=head1 EXPORT

Nothing by default.

=head1 AUTHOR

Meettya, C<< <meettya at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-config-yaml-modern at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Config-YAML-Modern>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 DEVELOPMENT

=head2 Repository

    https://github.com/Meettya/Config-YAML-Modern

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Config::YAML::Modern

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Config-YAML-Modern>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Config-YAML-Modern>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Config-YAML-Modern>

=item * Search CPAN

L<http://search.cpan.org/dist/Config-YAML-Modern/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Meettya.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of Config::YAML::Modern
