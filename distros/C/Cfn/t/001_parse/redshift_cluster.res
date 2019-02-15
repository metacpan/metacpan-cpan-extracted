{
  "Type": "AWS::Redshift::Cluster",
  "Properties": {
    "DBName" : "mydb", 
    "MasterUsername" : "master",
    "MasterUserPassword" : { "Ref" : "MasterUserPassword" },
    "NodeType" : "dw.hs1.xlarge",
    "ClusterType" : "single-node"
  }
}
