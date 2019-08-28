Feature: cpanfile parsing
  When the program is run without any arguments the cpanfile in the current directory is parsed.
  The names of the packages for all required modules are printed.

  Scenario: Packages for modules as required by the cpanfile are printed
    Given there is a cpanfile
    When the program is run
    Then the package names are printed
