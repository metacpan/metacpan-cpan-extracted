{
  "Type" : "AWS::EFS::FileSystem",
  "Properties" : {
    "FileSystemTags" : [
      {
        "Key" : "Name",
        "Value" : "TestFileSystem"
      }
    ]
  }
}
