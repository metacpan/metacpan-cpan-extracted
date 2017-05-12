
import org.keyczar.*;

public class TestEncrypt {
    public static void main(String[] args) {
        KeyczarFileReader reader = new KeyczarFileReader(args[0]);
        try {
            Encrypter crypter = new Encrypter(reader);
            System.out.print(crypter.encrypt(args[1])+"\n");
            
        } catch (org.keyczar.exceptions.KeyczarException e) {
            System.out.print("ng\n");
        }

    }
}
