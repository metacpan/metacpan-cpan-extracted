guard 'prove' do
  # prove modified test file
  watch(%r{^.*\.t$})

  # prove all files in t directory when some module gets modified
  # watch(%r{^.*\.pm$})    { "t" }

  # prove path/t/file.t when path/file.pm gets modified
  watch(%r{^(.*)/([^./]+)\.pm$}) {|m| m[1] + "/t/" + m[2] + ".t"}
end
