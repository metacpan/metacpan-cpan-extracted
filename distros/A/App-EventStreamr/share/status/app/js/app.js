'use strict';


// Declare app level module which depends on filters, and services
angular.module('myApp', [
  'ngRoute',
  'ngResource',
  'ui.bootstrap',
  'myApp.filters',
  'myApp.services',
  'myApp.directives',
  'myApp.controllers'
]).
config(['$routeProvider', function($routeProvider) {
  $routeProvider.when('/status', {templateUrl: 'partials/status.html', controller: 'status-list'});
  $routeProvider.otherwise({redirectTo: '/status'});
}]);
