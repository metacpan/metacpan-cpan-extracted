package Daje::Database::View::Super::VTreeList;
use Mojo::Base 'Daje::Database::Model::Super::Common::Base', -base, -signatures;
use v5.40;


has 'fields' => "'vatno', 'regno', 'support', 'homepage', 'companies_fkey', 'is_admin', 'company_type_fkey', 'users_fkey', 'company_type', 'active', 'user_phone', 'name', 'userid', 'company_phone', 'username'";
has 'primary_keys' => " ";
has 'foreign_keys' => "foreign_keys"
has 'view_name' => "v_companies_users";


1;