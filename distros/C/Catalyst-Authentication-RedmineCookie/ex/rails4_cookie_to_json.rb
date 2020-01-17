#!/usr/local/bin/ruby

# for secret_key_base
#
# https://gist.github.com/pdfrod/9c3b6b6f9aa1dc4726a5#gistcomment-2711128

require 'active_support'
require 'json'

class MyClass
  def initialize(key)
    # Default values for Rails 4 apps
    key_iter_num  = 1000
    key_size      = 32
    salt          = "encrypted cookie"
    signed_salt   = "signed encrypted cookie"
    key_generator = ActiveSupport::KeyGenerator.new(key, iterations: key_iter_num)
    secret        = key_generator.generate_key(salt)[0..key_size-1]
    sign_secret   = key_generator.generate_key(signed_salt)

    @encryptor = ActiveSupport::MessageEncryptor.new(secret, sign_secret, serializer: ActiveSupport::MessageEncryptor::NullSerializer)
  end
  def decrypt_session_cookie(cookie)
    cookie = CGI::unescape(cookie)

    JSON.generate( Marshal.load( @encryptor.decrypt_and_verify(cookie) ) )
  end
end

key = ":secret_key_base"
obj = MyClass.new(key)

while line = gets
  cookie = line.chomp

  begin
    puts obj.decrypt_session_cookie(cookie)
  rescue
    puts "ERROR"
  end
  STDOUT.flush
end
