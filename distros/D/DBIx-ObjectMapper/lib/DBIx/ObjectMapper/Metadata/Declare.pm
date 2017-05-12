package DBIx::ObjectMapper::Metadata::Declare;
use strict;
use warnings;
use base qw(DBIx::ObjectMapper::Metadata::Sugar);
use Sub::Exporter;

our @METHODS = (
    'Table',
    'get_declaration',
    @DBIx::ObjectMapper::Metadata::Sugar::ALL
);

Sub::Exporter::setup_exporter({
    exports => \@METHODS,
    groups  => {  default => \@METHODS },
});

my %DECLARE;

sub Table($$;$) {
    my ( $table, $col, $option ) = @_;
    my $pkg = caller;
    $DECLARE{$pkg} ||= +{};
    $DECLARE{$pkg}->{$table} = [ $table, $col, $option || undef ];
}

sub get_declaration {
    my $class = shift;
    if( @_ ) {
        my $table = shift;
        return @{$DECLARE{$class}->{$table}};
    }
    else {
        return values %{$DECLARE{$class}};
    }
}

1;
