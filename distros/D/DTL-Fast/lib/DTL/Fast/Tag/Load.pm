package DTL::Fast::Tag::Load;
use strict;
use utf8;
use warnings FATAL => 'all';

use DTL::Fast::Template;
$DTL::Fast::TAG_HANDLERS{load} = __PACKAGE__;

sub new
{
    my $proto = shift;
    my $parameter = shift;

    $parameter =~ s/(^\s+|['"]+|\s+$)//gs;
    my @modules = split /\s+/, $parameter;

    foreach my $module (@modules)
    {
        if (not $DTL::Fast::LOADED_MODULES{$module})
        {
            require Module::Load;
            Module::Load::load $module;
            $DTL::Fast::LOADED_MODULES{$module} = time;
        }
    }

    return;
}

1;
