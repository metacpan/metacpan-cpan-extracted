package    # hide from PAUSE
    DBIx::Squirrel::Transform::YAML::Syck;

use strict;
use warnings;
use YAML::Syck;

BEGIN {
    require DBIx::Squirrel unless keys(%DBIx::Squirrel::);
    require Exporter;
    $DBIx::Squirrel::Transform::YAML::Syck::VERSION   = $DBIx::Squirrel::VERSION;
    @DBIx::Squirrel::Transform::YAML::Syck::ISA       = qw/Exporter/;
    @DBIx::Squirrel::Transform::YAML::Syck::EXPORT_OK = qw/as_yaml/;
    @DBIx::Squirrel::Transform::YAML::Syck::EXPORT
        = @DBIx::Squirrel::Transform::YAML::Syck::EXPORT_OK;
}

sub as_yaml {
    return sub {
        local($YAML::Syck::ImplicitTyping)  = !!1;
        local($YAML::Syck::ImplicitUnicode) = !!1;
        local($YAML::Syck::SortKeys)        = !!1;
        return YAML::Syck::Dump(@_);
    };
}

1;
