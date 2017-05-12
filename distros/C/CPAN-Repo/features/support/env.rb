require 'cucumber/nagios/steps'

World do
  Webrat::Session.new(Webrat::MechanizeAdapter.new)
end




