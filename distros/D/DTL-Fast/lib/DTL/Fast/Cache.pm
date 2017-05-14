package DTL::Fast::Cache;
use strict;
use warnings FATAL => 'all';
# This is a prototype class for caching templates

sub new
{
    my ( $proto, %kwargs ) = @_;

    @kwargs{'hits', 'misses'} = (0, 0);

    return bless{ %kwargs }, $proto;
}

sub get
{
    my ( $self, $key ) = @_;

    my $template = $self->validate_template(
        $self->read_data(
            $key
        )
    );

    defined $template ?
        $self->{hits}++
                      : $self->{misses}++;

    return $template;
}

sub put
{
    my ( $self, $key, $template, %kwargs ) = @_;

    if (defined $template)
    {
        my @keys = ('cache', 'url_source');
        my @backup = @{$template}{@keys};
        delete @{$template}{@keys};
        $self->write_data($key, $template, %kwargs);
        @{$template}{@keys} = @backup;
    }
    return $self;
}

sub read_data
{
    my ( $self, $key ) = @_;
    die "read_data method was not defined in ".(ref $self);
}

sub clear
{
    my ( $self ) = @_;
    die "clear method was not defined in ".(ref $self);
}

sub write_data
{
    my ( $self, $key, $value ) = @_;

    die "write_data method was not defined in ".(ref $self);
}

sub validate_template
{
    my ( $self, $template ) = @_;
    return if (not defined $template);

    # here we check if template is still valid

    # check perl version
    return if (not $template->{perl} or $template->{perl} != $]);

    # check modules version
    if (my $modules = $template->{modules})
    {
        foreach my $module (keys(%$modules))
        {
            my $current_version = $module->VERSION // $DTL::Fast::VERSION;
            return if ($modules->{$module} ne $current_version);
        }
    }

    # check files modification
    if (my $files = $template->{inherits})
    {
        foreach my $file (keys( %$files ))
        {
            next if ($file eq 'inline');
            return if
                (not -e $file
                    or $files->{$file} != (stat($file))[9])
        }
    }

    return $template;
}

1;