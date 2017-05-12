Dancer2-Plugin-RoutePodCoverage
===============================

[![Build Status](https://travis-ci.org/drebolo/Dancer2-Plugin-RoutePodCoverage.png?branch=master)](https://travis-ci.org/drebolo/Dancer2-Plugin-RoutePodCoverage)

Dancer2 plugin to verify pod coverage in app routes.

To install this module from source:

````shell
  dzil install
````

To use this module in your Dancer2 route:

````perl
  use Dancer2;
  use Dancer2::Plugin::RoutePodCoverage;

  get '/' => sub {
      my $routes_couverage = routes_pod_coverage();

      # or

      packages_to_cover(['MYAPP::Routes','MYAPP::Routes::Something']);
      my $routes_couverage = routes_pod_coverage();

  };
````
