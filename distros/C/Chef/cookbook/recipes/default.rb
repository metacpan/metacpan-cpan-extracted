#
# Cookbook Name:: perl_recipe
# Recipe:: default
#
# Copyright 2009, Opscode
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

r = remote_directory "/tmp/perl_recipes" do
  source "perl_recipes"
  files_backup 0
  files_mode "0644"
  action :nothing # We don't want to do anything with this resource at run time
end

# We want this resource to run at compile time, not at execution time.
r.run_action(:create)

# Run all the perl recipes.
Dir["/tmp/perl_recipes/**/*.pl"].each do |f|
  output_json = nil
  Chef::Mixin::Command.popen4("perl #{f}", :waitlast => true) do |p, i, o, e|
    i.print(node.to_json)
    i.close
    output_json = o.gets(nil)
    o.close
  end
  returned_resources = JSON.parse(output_json)
  returned_resources['resource_collection'].each do |r|
    collection << r
  end
end

