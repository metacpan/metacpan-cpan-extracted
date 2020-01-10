#!/usr/local/bin/ruby

# for secret_token

require 'active_support'
require 'json'

class MyClass
  def initialize(key)
    @legacy_verifier = ActiveSupport::MessageVerifier.new(key, serializer: ActiveSupport::MessageEncryptor::NullSerializer)
  end
  def decrypt_session_cookie(cookie)
    cookie = CGI::unescape(cookie)

    JSON.generate( Marshal.load( @legacy_verifier.verify(cookie) ) )
  end
end

key = ":secret_token"
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
