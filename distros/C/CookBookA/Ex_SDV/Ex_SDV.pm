package CookBookA::Ex_SDV;

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);
@EXPORT = qw( SetDualVar );

$VERSION = '49.1';

bootstrap CookBookA::Ex_SDV $VERSION;


1;
