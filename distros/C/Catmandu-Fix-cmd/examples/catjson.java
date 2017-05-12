/*
 * Requires gson:
 *  javac -cp gson-2.2.2.jar catjson.java
 *  java -cp gson-2.2.2.jar:. catjson
 * 
 * Patrick . Hochstenbach @ UGent . be
 */
import java.io.BufferedReader;
import java.io.InputStreamReader;
import com.google.gson.JsonParser;
import com.google.gson.JsonElement;

public class catjson {
    public static void main(String[] args) throws Exception {
         BufferedReader stdin = new BufferedReader(new InputStreamReader(System.in)); 
         JsonParser parser = new JsonParser();
         String line; 
         
         while ((line = stdin.readLine()) != null) {
             JsonElement elem = parser.parse(line);
             System.out.println(elem);
         }
    }
}