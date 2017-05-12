Feature: cpan repo webserver index page
  It should retrun signature and list of available repos

  Scenario: As User I want to be able to see the version of cpan repo server
    When I go to "http://127.0.0.1:3000"
    Then I should see "cpan repo server version"

  Scenario: As User I want to be able to see list of available repos
    When I go to "http://127.0.0.1:3000"
    Then I should see "list of available repos"
