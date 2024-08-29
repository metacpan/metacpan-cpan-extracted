package    # hide from PAUSE
  DBIx::Squirrel::Transform::Data::Dumper;

use strict;
use warnings;
use Data::Dumper;

BEGIN {
    require DBIx::Squirrel unless keys(%DBIx::Squirrel::);
    require Exporter;
    $DBIx::Squirrel::Transform::Data::Dumper::VERSION   = $DBIx::Squirrel::VERSION;
    @DBIx::Squirrel::Transform::Data::Dumper::ISA       = qw/Exporter/;
    @DBIx::Squirrel::Transform::Data::Dumper::EXPORT_OK = qw/as_perl/;
    @DBIx::Squirrel::Transform::Data::Dumper::EXPORT    = @DBIx::Squirrel::Transform::Data::Dumper::EXPORT_OK;
}

sub as_perl {
    return sub {
        local($Data::Dumper::Terse)         = !!1;
        local($Data::Dumper::Indent)        = 1;
        local($Data::Dumper::Useqq)         = !!1;
        local($Data::Dumper::Deparse)       = !!1;
        local($Data::Dumper::Quotekeys)     = !!0;
        local($Data::Dumper::Sortkeys)      = !!1;
        local($Data::Dumper::Trailingcomma) = !!1;
        return Dumper(@_);
    };
}

1;
