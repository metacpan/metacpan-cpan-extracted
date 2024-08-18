use Modern::Perl;

package    # hide from PAUSE
  DBIx::Squirrel::Transform::Data::Dumper;


BEGIN {
    require DBIx::Squirrel
      unless defined($DBIx::Squirrel::VERSION);
    $DBIx::Squirrel::Transform::Data::Dumper::VERSION   = $DBIx::Squirrel::VERSION;
    @DBIx::Squirrel::Transform::Data::Dumper::ISA       = qw/Exporter/;
    @DBIx::Squirrel::Transform::Data::Dumper::EXPORT    = qw/as_perl/;
    @DBIx::Squirrel::Transform::Data::Dumper::EXPORT_OK = qw/as_perl/;
}

use Data::Dumper;


sub as_perl {
    return sub {
        local($Data::Dumper::Terse)         = !!1;
        local($Data::Dumper::Indent)        = 1;
        local($Data::Dumper::Useqq)         = !!1;
        local($Data::Dumper::Deparse)       = !!1;
        local($Data::Dumper::Quotekeys)     = !!0;
        local($Data::Dumper::Sortkeys)      = !!1;
        local($Data::Dumper::Trailingcomma) = !!1;
        return Dumper(shift);
    };
}

1;
