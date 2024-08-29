package    # hide from PAUSE
  DBIx::Squirrel::Transform::JSON::Syck;

use strict;
use warnings;
use JSON::Syck;

BEGIN {
    require DBIx::Squirrel unless keys(%DBIx::Squirrel::);
    require Exporter;
    $DBIx::Squirrel::Transform::JSON::Syck::VERSION   = $DBIx::Squirrel::VERSION;
    @DBIx::Squirrel::Transform::JSON::Syck::ISA       = qw/Exporter/;
    @DBIx::Squirrel::Transform::JSON::Syck::EXPORT_OK = qw/as_json/;
    @DBIx::Squirrel::Transform::JSON::Syck::EXPORT    = @DBIx::Squirrel::Transform::JSON::Syck::EXPORT_OK;
}

sub as_json {
    return sub {
        local($JSON::Syck::ImplicitTyping)  = !!1;
        local($JSON::Syck::ImplicitUnicode) = !!1;
        local($JSON::Syck::SortKeys)        = !!1;
        return JSON::Syck::Dump(@_);
    };
}

1;
